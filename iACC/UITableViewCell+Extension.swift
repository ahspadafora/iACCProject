//	
// Copyright © Essential Developer. All rights reserved.
//

import UIKit

extension UITableViewCell {
    func configure(_ item: ItemViewModel) {
        textLabel?.text = item.title
        detailTextLabel?.text = item.subtitle
    }
}
