//
//  CollectionViewCell.swift
//  Anlık
//
//  Created by Baran on 11.03.2026.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var lblGun: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lblDereceSehir: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .clear

        contentView.backgroundColor =
        UIColor.white.withAlphaComponent(0.2)

        contentView.layer.cornerRadius = 12
    }
}
