//
//  AnaEkranViewController.swift
//  Anlık
//
//  Created by Baran on 11.03.2026.
//
// AnaEkranViewController.swift
// AnaEkranViewController.swift

import UIKit
import WeatherKit
import CoreLocation

class AnaEkranViewController: UIViewController,
UICollectionViewDelegate,
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout,
CLLocationManagerDelegate,
UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var lblSehir: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lblDateTime: UILabel!
    @IBOutlet weak var lblDerece: UILabel!
    @IBOutlet weak var lblHavaDurumu: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!

    let locationManager = CLLocationManager()
    let weatherService = WeatherService()
    var gradientLayer = CAGradientLayer()
    var selectedLocation: CLLocation?

    struct GunlukHava {
        let gun: String
        let icon: String
        let max: Int
        let min: Int
    }

    var weeklyWeather: [GunlukHava] = []

    // MARK: - viewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()

        setupGradient()

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear

        setupSearchBar()

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        setDate()
    }

    // MARK: - SearchBar Tasarım

    func setupSearchBar() {
        searchBar.delegate = self
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .clear
        searchBar.barTintColor = .clear
        searchBar.isTranslucent = true

        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            textField.textColor = .white
            textField.layer.cornerRadius = 10
            textField.clipsToBounds = true
            textField.attributedPlaceholder = NSAttributedString(
                string: "Şehir veya ilçe ara",
                attributes: [.foregroundColor: UIColor.white]
            )
        }
    }

    // MARK: - Gradient

    func setupGradient() {
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor.systemBlue.cgColor,
            UIColor.systemTeal.cgColor
        ]
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    func updateBackground(condition: WeatherCondition, isDay: Bool) {
        var colors: [CGColor] = []

        if !isDay {
            colors = [
                UIColor(red: 0.05, green: 0.07, blue: 0.2, alpha: 1).cgColor,
                UIColor.black.cgColor
            ]
        } else {
            switch condition {
            case .clear, .mostlyClear:
                colors = [UIColor.systemYellow.cgColor, UIColor.systemOrange.cgColor]
            case .partlyCloudy:
                colors = [UIColor.systemBlue.cgColor, UIColor.systemGray.cgColor]
            case .cloudy, .mostlyCloudy:
                colors = [UIColor.systemGray.cgColor, UIColor.darkGray.cgColor]
            case .rain, .drizzle, .heavyRain:
                colors = [UIColor.systemBlue.cgColor, UIColor.systemIndigo.cgColor]
            case .thunderstorms:
                colors = [UIColor.systemPurple.cgColor, UIColor.black.cgColor]
            case .snow:
                colors = [UIColor.white.cgColor, UIColor.systemGray.cgColor]
            default:
                colors = [UIColor.systemBlue.cgColor, UIColor.systemTeal.cgColor]
            }
        }

        animateGradient(colors: colors)
    }

    func animateGradient(colors: [CGColor]) {
        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = gradientLayer.colors
        animation.toValue = colors
        animation.duration = 2
        gradientLayer.colors = colors
        gradientLayer.add(animation, forKey: "colorChange")
    }

    // MARK: - Tarih

    func setDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        lblDateTime.text = formatter.string(from: Date())
    }

    // MARK: - Konum

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        selectedLocation = location
        getCityName(location: location)
        manager.stopUpdatingLocation()

        Task {
            await getWeather(location: location)
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("Konum hatası: \(error.localizedDescription)")
    }

    // MARK: - Şehir İsmi

    func getCityName(location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first else { return }
            DispatchQueue.main.async {
                self.lblSehir.text = placemark.locality
            }
        }
    }

    // MARK: - SearchBar Arama

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let city = searchBar.text, !city.isEmpty else { return }
        searchBar.resignFirstResponder()

        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(city) { placemarks, error in
            if let location = placemarks?.first?.location {
                DispatchQueue.main.async {
                    self.lblSehir.text = city
                    self.selectedLocation = location

                    Task {
                        await self.getWeather(location: location)
                    }

                    // Veriyi UserDefaults'a kaydet
                    UserDefaults.standard.set(city, forKey: "selectedCityName")
                    UserDefaults.standard.set(location.coordinate.latitude, forKey: "selectedLat")
                    UserDefaults.standard.set(location.coordinate.longitude, forKey: "selectedLng")

                    // Detay sekmesine geç
                    self.tabBarController?.selectedIndex = 1
                }
            } else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "Şehir Bulunamadı",
                        message: "'\(city)' için sonuç bulunamadı. Lütfen tekrar deneyin.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Tamam", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - WeatherKit

    func getWeather(location: CLLocation) async {
        do {
            let weather = try await weatherService.weather(for: location)
            let current = weather.currentWeather

            DispatchQueue.main.async {
                self.lblDerece.text = "\(Int(current.temperature.value.rounded()))°C"
                self.lblHavaDurumu.text = current.condition.description

                self.updateBackground(
                    condition: current.condition,
                    isDay: current.isDaylight
                )

                if !current.isDaylight {
                    self.imageView.image = UIImage(named: "Icon=Night")
                } else {
                    let icon = self.getWeatherIcon(condition: current.condition)
                    self.imageView.image = UIImage(named: icon)
                }

                let daily = weather.dailyForecast
                self.weeklyWeather.removeAll()

                for forecast in daily.forecast.prefix(7) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "E"
                    formatter.locale = Locale(identifier: "tr_TR")

                    let day = formatter.string(from: forecast.date)
                    let max = Int(forecast.highTemperature.value.rounded())
                    let min = Int(forecast.lowTemperature.value.rounded())
                    let icon = self.getWeatherIcon(condition: forecast.condition)

                    self.weeklyWeather.append(
                        GunlukHava(gun: day, icon: icon, max: max, min: min)
                    )
                }

                self.collectionView.reloadData()
            }

        } catch {
            print("Weather error:", error)
        }
    }

    // MARK: - Icon Mapping

    func getWeatherIcon(condition: WeatherCondition) -> String {
        switch condition {
        case .clear:            return "Icon=Sunny"
        case .mostlyClear:      return "Icon=Sunny"
        case .partlyCloudy:     return "Icon=Partly Cloudy"
        case .mostlyCloudy:     return "Icon=Cloudy"
        case .cloudy:           return "Icon=Cloudy"
        case .drizzle:          return "Icon=Light Drizzle"
        case .rain:             return "Icon=Rainy"
        case .heavyRain:        return "Icon=Rainy"
        case .sunShowers:       return "Icon=Rainy with Sun"
        case .thunderstorms:    return "Icon=Thunderstorm"
        case .snow:             return "Icon=Snow"
        case .heavySnow:        return "Icon=Snowfall"
        case .sleet:            return "Icon=Sleet"
        case .blowingSnow:      return "Icon=Snowfall"
        default:                return "Icon=Cloudy"
        }
    }

    // MARK: - CollectionView

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return weeklyWeather.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "Cell",
            for: indexPath) as! CollectionViewCell

        let data = weeklyWeather[indexPath.row]
        cell.lblGun.text = data.gun
        cell.imageView.image = UIImage(named: data.icon)
        cell.lblDereceSehir.text = "\(data.max)° / \(data.min)°"

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 60)
    }
}
