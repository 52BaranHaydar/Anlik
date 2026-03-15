//
//  DetayViewController.swift
//  Anlık
//
//  Created by Baran on 14.03.2026.
//
// DetayViewController.swift
// DetayViewController.swift

import UIKit
import WeatherKit
import CoreLocation

struct HourWeather {
    let date: Date
    let temperature: Double
    let iconName: String
}

class DetayViewController: UIViewController,
UITableViewDelegate,
UITableViewDataSource,
CLLocationManagerDelegate {

    @IBOutlet weak var lblIsım: UILabel!
    @IBOutlet weak var imageLabel: UIImageView!
    @IBOutlet weak var lblDerece: UILabel!
    @IBOutlet weak var lblHavaDurumu: UILabel!
    @IBOutlet weak var lblNemOran: UILabel!
    @IBOutlet weak var lblRuzgar: UILabel!
    @IBOutlet weak var lblYagısOlasılık: UILabel!
    @IBOutlet weak var lblGunDoğumu: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var view1: UIView!
    @IBOutlet weak var view2: UIView!
    @IBOutlet weak var view3: UIView!
    @IBOutlet weak var view4: UIView!

    let locationManager = CLLocationManager()
    var hourlyWeather: [HourWeather] = []
    var isLocationLoaded = false

    // MARK: - viewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        styleViews()

        // Başlangıçta kendi konumunu al
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    // MARK: - viewWillAppear

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // AnaEkran'dan arama yapıldıysa UserDefaults'ta veri var
        if let cityName = UserDefaults.standard.string(forKey: "selectedCityName") {
            let lat = UserDefaults.standard.double(forKey: "selectedLat")
            let lng = UserDefaults.standard.double(forKey: "selectedLng")
            let location = CLLocation(latitude: lat, longitude: lng)

            DispatchQueue.main.async {
                self.lblIsım.text = cityName
            }

            fetchWeather(for: location)

            // Temizle — bir daha tetiklenmesin
            UserDefaults.standard.removeObject(forKey: "selectedCityName")
            UserDefaults.standard.removeObject(forKey: "selectedLat")
            UserDefaults.standard.removeObject(forKey: "selectedLng")
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        // Sadece ilk açılışta kendi konumunu yükle
        guard !isLocationLoaded, let location = locations.first else { return }
        isLocationLoaded = true
        manager.stopUpdatingLocation()
        updateCityLabel(for: location)
        fetchWeather(for: location)
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("Konum hatası: \(error.localizedDescription)")
    }

    // MARK: - Şehir İsmi (Konum bazlı)

    func updateCityLabel(for location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                let city = placemark.locality ?? placemark.administrativeArea ?? "?"
                DispatchQueue.main.async {
                    self.lblIsım.text = city
                }
            }
        }
    }

    // MARK: - WeatherKit

    func fetchWeather(for location: CLLocation) {
        Task {
            do {
                let weatherService = WeatherService()
                let weather = try await weatherService.weather(for: location)
                let current = weather.currentWeather

                DispatchQueue.main.async {
                    self.lblDerece.text = "\(Int(current.temperature.value.rounded()))°C"
                    self.lblHavaDurumu.text = current.condition.description

                    let iconName = self.weatherConditionToIconName(condition: current.condition)
                    self.imageLabel.image = UIImage(named: iconName)

                    self.lblNemOran.text = "\(Int(current.humidity * 100))%"
                    self.lblRuzgar.text = "\(Int(current.wind.speed.value)) km/h"

                    let now = Date()
                    if let nearestHour = weather.hourlyForecast.forecast.min(by: {
                        abs($0.date.timeIntervalSince(now)) < abs($1.date.timeIntervalSince(now))
                    }) {
                        self.lblYagısOlasılık.text = "\(Int(nearestHour.precipitationChance * 100))%"
                    } else {
                        self.lblYagısOlasılık.text = "-"
                    }

                    if let sunrise = weather.dailyForecast.first?.sun.sunrise {
                        let formatter = DateFormatter()
                        formatter.timeStyle = .short
                        self.lblGunDoğumu.text = formatter.string(from: sunrise)
                    }

                    self.updateBackgroundColor(for: iconName)

                    self.hourlyWeather = weather.hourlyForecast.forecast.map { hourly in
                        let icon = self.weatherConditionToIconName(condition: hourly.condition)
                        return HourWeather(
                            date: hourly.date,
                            temperature: hourly.temperature.value,
                            iconName: icon
                        )
                    }

                    self.tableView.reloadData()
                }

            } catch {
                print("Weather fetch error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - TableView

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return hourlyWeather.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "DetayCell",
            for: indexPath) as! DetayTableViewCell

        let hourly = hourlyWeather[indexPath.row]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEEE HH:mm"
        cell.lblZaman.text = formatter.string(from: hourly.date).capitalized
        cell.lblHissedilenDerece.text = "\(Int(hourly.temperature))°C"
        cell.detayImageView.image = UIImage(named: hourly.iconName)
        cell.backgroundColor = self.view.backgroundColor

        return cell
    }

    // MARK: - Icon Mapping

    func weatherConditionToIconName(condition: WeatherCondition) -> String {
        switch condition {
        case .clear, .mostlyClear:      return "Icon=Sunny"
        case .partlyCloudy:             return "Icon=Partly Cloudy"
        case .mostlyCloudy, .cloudy:    return "Icon=Cloudy"
        case .drizzle:                  return "Icon=Light Drizzle"
        case .rain, .heavyRain:         return "Icon=Rainy"
        case .sunShowers:               return "Icon=Rainy with Sun"
        case .thunderstorms:            return "Icon=Thunderstorm"
        case .snow, .heavySnow:         return "Icon=Snow"
        case .sleet:                    return "Icon=Sleet"
        case .blowingSnow:              return "Icon=Snowfall"
        default:                        return "Icon=Cloudy"
        }
    }

    // MARK: - Arka Plan Rengi

    func updateBackgroundColor(for iconName: String) {
        let color: UIColor

        switch iconName {
        case "Icon=Sunny":
            color = UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.9)
        case "Icon=Partly Cloudy":
            color = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 0.85)
        case "Icon=Cloudy":
            color = UIColor(red: 0.6, green: 0.6, blue: 0.7, alpha: 0.85)
        case "Icon=Rainy", "Icon=Rainy with Sun", "Icon=Light Drizzle":
            color = UIColor(red: 0.2, green: 0.5, blue: 0.7, alpha: 0.9)
        case "Icon=Thunderstorm":
            color = UIColor(red: 0.5, green: 0.0, blue: 0.7, alpha: 0.9)
        case "Icon=Snow", "Icon=Snowfall", "Icon=Sleet":
            color = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.9)
        case "Icon=Night":
            color = UIColor(red: 0.05, green: 0.05, blue: 0.2, alpha: 0.95)
        default:
            color = UIColor.systemBackground
        }

        self.view.backgroundColor = color

        for v in [view1, view2, view3, view4] {
            v?.backgroundColor = color.withAlphaComponent(0.85)
            v?.layer.cornerRadius = 12
            v?.layer.borderWidth = 2
            v?.layer.borderColor = UIColor.white.cgColor
            v?.clipsToBounds = true
        }

        tableView.reloadData()
    }

    func styleViews() {
        for v in [view1, view2, view3, view4] {
            v?.layer.cornerRadius = 12
            v?.layer.borderWidth = 2
            v?.layer.borderColor = UIColor.white.cgColor
            v?.clipsToBounds = true
        }
    }
}
