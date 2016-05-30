//
//  ImageTapHelper.swift
//  Stepic
//
//  Created by Alexander Karpov on 30.05.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Foundation

class ImageTapHelper {
    
    var imageView : UIImageView!
    var action: (UITapGestureRecognizer -> Void)!
    
    init(imageView: UIImageView, action: (UITapGestureRecognizer -> Void)) {
        self.imageView = imageView
        self.action = action
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ImageTapHelper.didTapOnImageView(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        imageView.userInteractionEnabled = true
        imageView.addGestureRecognizer(tapRecognizer)
    }
    
    @objc func didTapOnImageView(recognizer: UITapGestureRecognizer) {
        action(recognizer)
    }

    
    deinit {
        print("did deinit image tap helper")
    }
}