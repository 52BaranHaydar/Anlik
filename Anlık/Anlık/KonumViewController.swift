//
//  KonumViewController.swift
//  Anlık
//
//  Created by Baran on 15.03.2026.
//
import UIKit

class KonumViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var searchBox: UISearchBar!
    @IBOutlet weak var tableViewController: UITableView!
    
    var konumListesi : [KonumModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableViewController.dataSource = self
        tableViewController.delegate = self
        searchBox.delegate = self
        
        // --- EKLEME: Hücre yüksekliğini otomatik ayarla ---
        tableViewController.rowHeight = UITableView.automaticDimension
        tableViewController.estimatedRowHeight = 100
        // ------------------------------------------------
        
        konumListesi.append(KonumModel(sehir: "Antalya", zaman: "10:00", derece: "21°C", icon: "cloud.sun"))
        konumListesi.append(KonumModel(sehir: "Trabzon", zaman: "09:45", derece: "18°C", icon: "cloud.rain"))
        konumListesi.append(KonumModel(sehir: "İstanbul", zaman: "09:30", derece: "20°C", icon: "cloud"))
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return konumListesi.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCell
        let konum = konumListesi[indexPath.row]
        
        cell.lblSehir.text = konum.sehir
        cell.lblZaman.text = konum.zaman
        cell.lblDerece.text = konum.derece
        
        // SF Symbols kullanıyorsan systemName tercih etmelisin
        cell.tableImageView.image = UIImage(systemName: konum.icon)
        
        // --- EKLEME: Metin sığmazsa fontu otomatik küçült ---
        cell.lblSehir.adjustsFontSizeToFitWidth = true
        cell.lblSehir.minimumScaleFactor = 0.5 // En fazla yarı yarıya küçülür
        // ---------------------------------------------------
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            konumListesi.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    // Not: Fonksiyon adındaki yazım hatasını düzelttim (searchBarSearchButtonClicked)
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let sehir = searchBar.text, !sehir.isEmpty {
            let yeniKonum = KonumModel(sehir: sehir, zaman: "Şimdi", derece: "--", icon: "cloud")
            konumListesi.append(yeniKonum)
            tableViewController.reloadData()
        }
        searchBar.resignFirstResponder()
    }
}
