//
//  MultiImagesCardView.swift
//  MultiImagesCardView
//
//  Created by João Pedro Giarrante on 03/08/21.
//

import SwiftUI

struct MultiImagesCardView_Previews: PreviewProvider {
    static var previews: some View {
        let card = Card(image: #imageLiteral(resourceName: "Image1"))
        MultiImagesCardView(isFullScreen: false, card: card, squareSide: 220, isSingleImage: true)
    }
}

struct Card: Identifiable, Equatable {
    
    // MARK: - Initializer
    
    init(id: UUID = UUID(), image: UIImage, isEmptyCard: Bool = false) {
        self.id = id
        self.image = image
        self.isEmptyCard = isEmptyCard
    }
    
    // MARK: - Properties
    
    let id: UUID
    let image: UIImage
    let isEmptyCard: Bool
}

struct MultiImagesCardView: View {
    
    // MARK: - Initializer
    
    init(isFullScreen: Bool, card: Card, squareSide: CGFloat, isSingleImage: Bool) {
        self.isFullScreen = isFullScreen
        self.card = card
        self.squareSide = squareSide
        self.isSingleImage = isSingleImage
    }
    
    // MARK: - Properties
    
    private let isFullScreen: Bool
    private let card: Card
    private let squareSide: CGFloat
    private let isSingleImage: Bool
    
    // MARK: - Body
    
    var body: some View {
        
        if !isFullScreen {
            RoundedRectangle(cornerRadius: MultiImagesView.Constants.radius, style: .continuous)
                .foregroundColor(.clear)
                .background(
                    Image(uiImage: card.image)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .frame(width: squareSide, height: squareSide)
                        .cornerRadius(MultiImagesView.Constants.radius)
                        .shadow(color: isSingleImage ? .clear : MultiImagesView.Constants.greyColor, radius: MultiImagesView.Constants.radius, x: 0, y: MultiImagesView.Constants.shadowY)
                        .overlay(
                            RoundedRectangle(cornerRadius: MultiImagesView.Constants.radius)
                                .stroke(MultiImagesView.Constants.greyColor, lineWidth: card.isEmptyCard ? 0 : MultiImagesView.Constants.lineWidth)
                        )
                )
                .transition(.identity)
                .animation(MultiImagesView.Constants.animation)
        } else {
            RoundedRectangle(cornerSize: .zero)
                .foregroundColor(.clear)
                .overlay(
                    Image(uiImage: card.image)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .frame(width: getIdealSide(), height: getIdealSide()).ignoresSafeArea()
                )
                .transition(.scale)
                .animation(.spring())
        }
    }
    
    func getIdealSide() -> CGFloat {
        let side = UIScreen.main.bounds.height < UIScreen.main.bounds.width ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        return side
    }
}
