//
//  TableViewCell.swift
//  Anlık
//
//  Created by Baran on 11.03.2026.
//

import UIKit

class TableViewCell: UITableViewCell {
    
    @IBOutlet weak var lblSehir: UILabel!
    
    @IBOutlet weak var lblZaman: UILabel!
    
    @IBOutlet weak var tableImageView: UIImageView!
    
    @IBOutlet weak var lblDerece: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
    }

    @IBAction func infoButtonClicked(_ sender: UIButton) {
        
    }
    
    @IBAction func deleteButtonClicked(_ sender: UIButton) {
        
    }
    
    
}
