//
//  DetayTableViewCell.swift
//  Anlık
//
//  Created by Baran on 14.03.2026.
//

import UIKit

class DetayTableViewCell: UITableViewCell {

    @IBOutlet weak var lblZaman: UILabel!
    @IBOutlet weak var detayImageView: UIImageView!
    @IBOutlet weak var lblHissedilenDerece: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        detayImageView.contentMode = .scaleAspectFit
    }
}
