//
//  MultiImagesDeck.swift
//  MultiImagesDeck
//
//  Created by João Pedro Giarrante on 03/08/21.
//

import SwiftUI

struct MultiImagesDeck {
    
    // MARK: - Initializers
    
    init(with images: [UIImage]) {
        self.cards = images.compactMap({ Card(image: $0) })
    }
    
    // MARK: - Properties
    private var fullScreenActiveCardOffset: CGSize = .zero
    private var storedActiveCardOffset: CGSize = .zero
    var activeCardIndex: Int = 0
    var cards: [Card]
    var activeCard: Card? {
        return cards.count >= activeCardIndex && activeCardIndex > 0 ? cards[activeCardIndex] : nil
    }
}

// MARK: - Mutating API

extension MultiImagesDeck {
    mutating func move(to side: CardsSide) {
        switch side {
        case .left:
            activeCardIndex = activeCardIndex+1
        case .right:
            activeCardIndex = activeCardIndex-1
        }
        storedActiveCardOffset = .zero
        fullScreenActiveCardOffset = .zero
    }
    
    mutating func onEndedAnimation() {
        if storedActiveCardOffset.width*MultiImagesView.Constants.movementMultiplier < -MultiImagesView.Constants.movementDistance {
            move(to: .left)
        } else if storedActiveCardOffset.width*MultiImagesView.Constants.movementMultiplier > MultiImagesView.Constants.movementDistance {
            move(to: .right)
        }
        storedActiveCardOffset = .zero
    }
    
    mutating func onChangedAnimation(with drag: DragGesture.Value) {
        if validateDrag(drag) {
            storedActiveCardOffset = drag.translation
        }
    }
    
    mutating func onChangedFullscreenAnimation(with drag: DragGesture.Value) {
        fullScreenActiveCardOffset = drag.translation
    }
    
    mutating func onEndedFullscreenAnimation(drag: DragGesture.Value, geometry: GeometryProxy) {
        if abs(fullScreenActiveCardOffset.width) > geometry.size.width*0.5 {
            if drag.translation.width > 0 {
                move(to: .right)
            } else {
                move(to: .left)
            }
        }
        fullScreenActiveCardOffset = .zero
    }
}

// MARK: - Public API

extension MultiImagesDeck {
    
    // MARK: Helpers
    
    enum CardsSide {
        case left
        case right
    }
    
    /// Returns the index of an `Card`.
    func index(of card: Card?) -> Int {
        guard let safeCard = card, let index = cards.firstIndex(of: safeCard) else { return 0 }
        return index+1
    }
    
    // MARK: Cards zIndex
    
    func zIndex(of card: Card) -> Double {
        enum zIndexPriority {
            static let high: Int = 99999
            static let medium: Int = 9999
            static let low: Int = 999
        }
        
        if card == activeCard {
            // Active Card is always medium
            return Double(zIndexPriority.medium)
        } else {
            // This way we block both the side items to swipe
            if isDistantEnoughToSwipe() {
                if isSwippingRight() && card == cards[activeCardIndex-1] {
                    return Double(zIndexPriority.high)
                } else if isSwippingLeft() && card == cards[activeCardIndex+1] {
                    return Double(zIndexPriority.high)
                }
            }
            
            // Returns the index compairing to the position
            var rightAditionalIndex = 0
            var leftAditionalIndex = 0
            
            if isSwippingRight() {
                rightAditionalIndex = -zIndexPriority.low
            } else if isSwippingLeft() {
                leftAditionalIndex = -zIndexPriority.low
            }
            
            let indexFloat = cards.count - relativeIndex(of: card)
            let side = side(of: card)
            
            switch side {
            case .left:
                return Double(indexFloat + leftAditionalIndex)
            case .right:
                return Double(indexFloat + rightAditionalIndex)
            }
        }
    }
    
    // MARK: Cards Scale
    
    func scale(of card: Card) -> CGFloat {
        if card == activeCard {
            return activeCardScale()
        } else {
            return backCardsScale(for: card)
        }
    }
    
    // MARK: Cards Offset
    
    func offset(for card: Card) -> CGSize {
        if card == activeCard {
            return activeCardOffset()
        } else {
            return CGSize(width: backCardsOffset(for: card), height: 0)
        }
    }
    
    func fullScreenOffset(for card: Card, with geometry: GeometryProxy) -> CGSize {
        /*
         This makes sure that each image has an offSet of its width, multiplied by its index.
         That creates the swiping animation in fullscreen mode.
         */
        return CGSize(width: (CGFloat(index(of: card)-1) * geometry.size.width)-1 + fullScreenActiveCardOffset.width, height: 0)
    }
    
    // MARK: Cards Rotation
    
    func rotation(for card: Card) -> Angle {
        if card == activeCard {
            return activeCardRotation()
        } else {
            return backCardsRotation(for: card)
        }
    }
}


// MARK: - Private API

private extension MultiImagesDeck {
    
    // MARK: Helpers
    
    /// Returns the index of an `Card`, related to the card that its active.
    /// e.g.:
    /// If the card of index `3` is active,
    /// the ones with index `2` and `4` would have an `relativeIndex` equal to `1`.
    func relativeIndex(of card: Card) -> Int {
        let relative = index(of: card) - activeCardIndex
        return relative > 0 ? abs(relative) - 1 : abs(relative) + 1
    }
    
    func side(of card: Card) -> CardsSide {
        if (index(of: card) - activeCardIndex) > 0 {
            return .right
        } else {
            return .left
        }
    }
    
    
    func isSwippingLeft() -> Bool {
        return storedActiveCardOffset.width < 0
    }
    
    func isSwippingRight() -> Bool {
        return storedActiveCardOffset.width > 0
    }
    
    /// Retuns an `Bool` value that indicates if the dragging movement from the user reached the maximum distance, enough to perform an swipe.
    func isDistantEnoughToSwipe() -> Bool {
        let actualDistance = storedActiveCardOffset.width*MultiImagesView.Constants.movementMultiplier
        return abs(actualDistance) > MultiImagesView.Constants.movementDistance
    }
    
    /// Returns the correct `offset` width of the active card, compensating the extra width, after ther dragging movement reaches the necessary width to perfom an slide.
    /// This creates the animation of the cards swiping to the back of the previous one, just like an cheap.
    func getWidthCompensatingExtraMovement() -> CGFloat {
        let currentOffsetWidth = storedActiveCardOffset.width*MultiImagesView.Constants.movementMultiplier
        let extraOffsetWidth = abs(currentOffsetWidth) - MultiImagesView.Constants.movementDistance
        if extraOffsetWidth > MultiImagesView.Constants.movementDistance { return 0 }
        let finalOffSideWidth = MultiImagesView.Constants.movementDistance - extraOffsetWidth
        return isSwippingRight() ? finalOffSideWidth : -finalOffSideWidth
    }
    
    /// Returns a value between `1` and `0` that represents how close is the current `storedActiveCardOffset` width to the maximum active card width.
    func getActiveCardOffsetPercentage() -> CGFloat {
        if abs(storedActiveCardOffset.width) < MultiImagesView.Constants.movementDistance {
            return abs(storedActiveCardOffset.width) / MultiImagesView.Constants.movementDistance
        } else {
            return 1
        }
    }
    
    /// Retuns an `Bool` value that indicates if the dragging movement of the user should reflect on the card offset.
    func validateDrag(_ drag: DragGesture.Value) -> Bool {
        // The last item should not bounce to the left.
        let lastItemDraggingLeft = activeCard == cards.last && drag.translation.width < 0
        // The first item should not bounce to the right.
        let firstItemDraggingRight = activeCard == cards.first && drag.translation.width > 0
        /*
         When dragging an activeCard, after reaching more than 1.5x the needed width to perform an swipe movement,
         we start ignoring the dragging to it won't re-appear in the other side.
         */
        let outLimitsDrag = (abs(drag.translation.width/2) > MultiImagesView.Constants.movementDistance)
        return !(firstItemDraggingRight || lastItemDraggingLeft || outLimitsDrag)
    }
    
    // MARK: Cards Scale
    
    /// Returns the scale of the active card. The scale is inversely proportional to `offSet` width.
    func activeCardScale() -> CGFloat {
        let activeCardOffset = storedActiveCardOffset.width*MultiImagesView.Constants.movementMultiplier
        let halfOffset = abs(activeCardOffset/2)
        let maximumOffSetToSwipe = MultiImagesView.Constants.movementDistance
        /*
         The minimum scale will be 0.5.
         It will happen when the card is in the exact maximum distance from the origin.
         In this case, halfOffset/maximumOffSetToSwipe will equal 0.5.
         
         Other than this case, halfOffset/maximumOffSetToSwipe will result
         on a number lower than 0.5, and higher or equal to 0.
         */
        let calculatedScale = abs(1 - (halfOffset/maximumOffSetToSwipe))
        if isDistantEnoughToSwipe() {
            return 1 - calculatedScale
        } else {
            return calculatedScale
        }
    }
    
    /// Returns the scale of the back cards. The scale is inversely proportional to `offSet` width of that card, that is proportional to its `relatedIndex`.
    func backCardsScale(for card: Card) -> CGFloat {
        let percentageMovement = getActiveCardOffsetPercentage()
        let cardIndex = CGFloat(relativeIndex(of: card))
        let side = side(of: card)
        
        /// Local function that returns the scale of an card, inversely proportional to its `index`.
        func scaleForIndex(_ index: Double) -> CGFloat {
            let decimalScale = pow(MultiImagesView.Constants.scaleMultiplier, index)
            let doubleScale = NSDecimalNumber(decimal: Decimal(decimalScale)).doubleValue
            let finalScale = CGFloat(doubleScale)
            return finalScale
        }
        
        switch side {
        case .left:
            if isSwippingRight() {
                return scaleForIndex(cardIndex-percentageMovement)
            } else {
                return scaleForIndex(cardIndex+percentageMovement)
            }
        case .right:
            if isSwippingRight() {
                return scaleForIndex(cardIndex+percentageMovement)
            } else {
                return scaleForIndex(cardIndex-percentageMovement)
            }
        }
    }
    
    // MARK: Cards Offset
    
    /// Returns the `offSet` of the active card.
    func activeCardOffset() -> CGSize {
        if isDistantEnoughToSwipe() {
            let finalOffSideWidth = getWidthCompensatingExtraMovement()
            /*
             The offsetHeight is proportional to the offsetWidth in a 0.4x relation.
             We divide the finalOffSideWidth by the MultiImagesView.Constants.movementMultiplier before calculating
             because the offsetHeight should not consider the horizontal movement multiplier.
             */
            let finalOffSideHeight = -abs(finalOffSideWidth/MultiImagesView.Constants.movementMultiplier)*0.4
            return CGSize(width: finalOffSideWidth, height: finalOffSideHeight)
        } else {
            return CGSize(width: storedActiveCardOffset.width*MultiImagesView.Constants.movementMultiplier, height: -abs(storedActiveCardOffset.width)*0.4)
        }
    }
    
    /// Returns the `offSet` of the back cards. The offset is proportional to its `relativeIndex`.
    func backCardsOffset(for card: Card) -> CGFloat {
        let deckPosition = CGFloat(relativeIndex(of: card))
        let side = side(of: card)
        /*
         Each card has an 12.5% of the activeCard width, times its relativeIndex
         of offSet from the one before.
         e.g.:
         If the activeCard has a width of 200,
         the third card will have (0.125 x 200)x3 in offset.
         */
        let offSetMultiplier = 0.125 * MultiImagesView.Constants.squareSide
        let offset = deckPosition * offSetMultiplier
        let percentageMovement = getActiveCardOffsetPercentage()
        
        if isSwippingRight() {
            switch side {
            case .left:
                let finalOffset = offset-(offSetMultiplier*percentageMovement)
                return -finalOffset
            case .right:
                let finalOffset = offset+(offSetMultiplier*percentageMovement)
                return finalOffset
            }
        } else {
            switch side {
            case .left:
                let finalOffset = offset+(offSetMultiplier*percentageMovement)
                return -finalOffset
            case .right:
                let finalOffset = offset-(offSetMultiplier*percentageMovement)
                return finalOffset
            }
        }
    }
    
    // MARK: Cards Rotation
    
    func activeCardRotation() -> Angle {
        if isDistantEnoughToSwipe() {
            return .degrees(Double(getWidthCompensatingExtraMovement()/MultiImagesView.Constants.movementMultiplier) / 10)
        } else {
            return .degrees(Double(storedActiveCardOffset.width) / 10)
        }
    }
    
    func backCardsRotation(for card: Card) -> Angle {
        let side = side(of: card)
        func rotationForAboveCard(_ card: Card, _ side: CardsSide, _ degrees: Angle, _ percentageMovement: CGFloat) -> Angle {
            let aboveDegrees = Angle.degrees(-Double(relativeIndex(of: card)+1)*3)
            let finalDegrees = degrees + ((degrees-aboveDegrees)*percentageMovement)
            return finalDegrees
        }
        func rotationForBehindCard(_ card: Card, _ side: CardsSide, _ degrees: Angle, _ percentageMovement: CGFloat) -> Angle {
            let behindDegrees = Angle.degrees(-Double(relativeIndex(of: card)+1)*3)
            let finalDegrees = degrees - ((behindDegrees-degrees)*percentageMovement)
            return finalDegrees
        }
        let percentageMovement = abs(storedActiveCardOffset.width) < MultiImagesView.Constants.movementDistance ? abs(storedActiveCardOffset.width) / MultiImagesView.Constants.movementDistance : 1
        let degrees = Angle.degrees(-Double(relativeIndex(of: card))*3)
        if isSwippingRight() {
            switch side {
            case .left:
                return rotationForAboveCard(card, side, degrees, percentageMovement)
            case .right:
                return -rotationForBehindCard(card, side, degrees, -percentageMovement)
            }
        } else {
            switch side {
            case .left:
                return rotationForAboveCard(card, side, degrees, -percentageMovement)
            case .right:
                return -rotationForBehindCard(card, side, degrees, percentageMovement)
            }
        }
    }
}
