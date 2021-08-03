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
        MultiImagesCardView(isFullScreen: false, card: card)
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
    
    init(isFullScreen: Bool, card: Card) {
        self.isFullScreen = isFullScreen
        self.card = card
    }
    
    // MARK: - Properties
    
    private let isFullScreen: Bool
    private let card: Card
    
    // MARK: - Body
    
    var body: some View {
        
        if !isFullScreen {
            RoundedRectangle(cornerRadius: MultiImagesView.Constants.radius, style: .continuous)
                .foregroundColor(.clear)
                .background(
                    Image(uiImage: card.image)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .frame(width: MultiImagesView.Constants.squareSide, height: MultiImagesView.Constants.squareSide)
                        .cornerRadius(MultiImagesView.Constants.radius)
                        .shadow(color: MultiImagesView.Constants.greyColor, radius: MultiImagesView.Constants.radius, x: MultiImagesView.Constants.shadowX, y: MultiImagesView.Constants.shadowY)
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
