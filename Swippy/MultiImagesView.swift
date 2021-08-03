//
//  MultiImagesView.swift
//  swippy
//
//  Created by João Pedro Giarrante on 22/07/21.
//

import SwiftUI

struct MultiImagesView_Previews: PreviewProvider {
    static var previews: some View {
        MultiImagesView(with: [#imageLiteral(resourceName: "Image1"), #imageLiteral(resourceName: "Image2"), #imageLiteral(resourceName: "Image1"), #imageLiteral(resourceName: "Image2"), #imageLiteral(resourceName: "Image1"), #imageLiteral(resourceName: "Image2")])
    }
}


import SwiftUI

struct Card: Identifiable, Equatable {
    
    let id: UUID
    let image: UIImage
    let isEmptyCard: Bool
    
    init(id: UUID = UUID(), image: UIImage, isEmptyCard: Bool = false) {
        self.id = id
        self.image = image
        self.isEmptyCard = isEmptyCard
    }
}

enum CardsSide {
    case left
    case right
}

struct Deck {
    
    // MARK: - Initializers
    
    init(with images: [UIImage]) {
        self.cards = images.compactMap({ Card(image: $0) })
        self.activeCard = cards.first
    }
    
    // MARK: - Properties
    
    var activeCardIndex: Int = 0
    
    var activeCard: Card?
    var fullScreenActiveCardOffset: CGSize = .zero
    var storedActiveCardOffset: CGSize = .zero
    var cards: [Card]
    
    
    // MARK: - Public API
    
    func index(of card: Card) -> Int {
        guard let index = cards.firstIndex(of: card) else { return 0 }
        return index + 1
    }
    
}


// MARK: - Helper

private extension Deck {
    
    /// Returns the index of an `Card`.
    func index(of card: Card?) -> Int {
        guard let safeCard = card else { return 0 }
        return cards.firstIndex(of: safeCard) ?? 0
    }
    
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
        let outLimitsDrag = (abs(drag.translation.width/2) > CardView.Constants.movementDistance)
        return !(firstItemDraggingRight || lastItemDraggingLeft || outLimitsDrag)
    }
    
    /// Retuns an `Bool` value that indicates if the dragging movement from the user reached the maximum distance, enough to perform an swipe.
    func isDistantEnoughToSwipe() -> Bool {
        let actualDistance = storedActiveCardOffset.width*CardView.Constants.movementMultiplier
        return abs(actualDistance) > CardView.Constants.movementDistance
    }
    
    /// Returns the correct `offset` width of the active card, compensating the extra width, after ther dragging movement reaches the necessary width to perfom an slide.
    /// This creates the animation of the cards swiping to the back of the previous one, just like an cheap.
    func getWidthCompensatingExtraMovement() -> CGFloat {
        let currentOffsetWidth = storedActiveCardOffset.width*CardView.Constants.movementMultiplier
        let extraOffsetWidth = abs(currentOffsetWidth) - CardView.Constants.movementDistance
        if extraOffsetWidth > CardView.Constants.movementDistance { return 0 }
        let finalOffSideWidth = CardView.Constants.movementDistance - extraOffsetWidth
        return isSwippingRight() ? finalOffSideWidth : -finalOffSideWidth
    }
    
    /// Returns a value between `1` and `0` that represents how close is the current `storedActiveCardOffset` width to the maximum active card width.
    func getActiveCardOffsetPercentage() -> CGFloat {
        if abs(storedActiveCardOffset.width) < CardView.Constants.movementDistance {
            return abs(storedActiveCardOffset.width) / CardView.Constants.movementDistance
        } else {
            return 1
        }
    }
}

// MARK: - Position Source

private extension Deck {
    
    // MARK: zIndex
    
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
    
    
    // MARK: Scale
    
    func scale(of card: Card) -> CGFloat {
        if card == activeCard {
            return activeCardScale()
        } else {
            return backCardsScale(for: card)
        }
    }
    
    /// Returns the scale of the active card. The scale is inversely proportional to `offSet` width.
    func activeCardScale() -> CGFloat {
        let activeCardOffset = storedActiveCardOffset.width*CardView.Constants.movementMultiplier
        let halfOffset = abs(activeCardOffset/2)
        let maximumOffSetToSwipe = CardView.Constants.movementDistance
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
            let decimalScale = pow(CardView.Constants.scaleMultiplier, index)
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
    
    // MARK: Offset
    
    func offset(for card: Card) -> CGSize {
        if card == activeCard {
            return activeCardOffset()
        } else {
            return CGSize(width: backCardsOffset(for: card), height: 0)
        }
    }
    
    
    /// Returns the `offSet` of the active card.
    func activeCardOffset() -> CGSize {
        if isDistantEnoughToSwipe() {
            let finalOffSideWidth = getWidthCompensatingExtraMovement()
            /*
             The offsetHeight is proportional to the offsetWidth in a 0.4x relation.
             We divide the finalOffSideWidth by the CardView.Constants.movementMultiplier before calculating
             because the offsetHeight should not consider the horizontal movement multiplier.
             */
            let finalOffSideHeight = -abs(finalOffSideWidth/CardView.Constants.movementMultiplier)*0.4
            return CGSize(width: finalOffSideWidth, height: finalOffSideHeight)
        } else {
            return CGSize(width: storedActiveCardOffset.width*CardView.Constants.movementMultiplier, height: -abs(storedActiveCardOffset.width)*0.4)
        }
    }
    
    func backCardsOffset(for card: Card) -> CGFloat {
        let deckPosition = CGFloat(relativeIndex(of: card))
        let side = side(of: card)
        // Each card has an 12.5% offset related to its width
        let offSetMultiplier = CardView.Constants.squareSide / 8
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
    
    // MARK: Rotation
    
    func rotation(for card: Card) -> Angle {
        if card == activeCard {
            return activeCardRotation()
        } else {
            return backCardsRotation(for: card)
        }
    }
    
    func activeCardRotation() -> Angle {
        if isDistantEnoughToSwipe() {
            return .degrees(Double(getWidthCompensatingExtraMovement()/CardView.Constants.movementMultiplier) / 10)
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
        let percentageMovement = abs(storedActiveCardOffset.width) < CardView.Constants.movementDistance ? abs(storedActiveCardOffset.width) / CardView.Constants.movementDistance : 1
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

// MARK: - Mutating API

extension Deck {
    mutating func move(to side: CardsSide) {
        switch side {
        case .left:
            activeCardIndex = activeCardIndex+1
            activeCard = cards[activeCardIndex]
        case .right:
            activeCardIndex = activeCardIndex-1
            activeCard = cards[activeCardIndex]
        }
        storedActiveCardOffset = .zero
        fullScreenActiveCardOffset = .zero
    }
}


// MARK: - MultiImagesView

struct MultiImagesView: View {
    
    @Namespace var animation
    @State var showSheet = false
    @State var showDetail = false
    @State private var showFullScreen = false
    @State private var detailSelection = 0
    @State var deck: Deck
    @State var navBarHidden: Bool = false
    
    let coloredNavAppearance = UINavigationBarAppearance()
    
    init(with images: [UIImage]) {
        coloredNavAppearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = coloredNavAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredNavAppearance
        _deck = State(initialValue: Deck(with: images))
    }
    
    private func onEndedAnimation() {
        if deck.storedActiveCardOffset.width*CardView.Constants.movementMultiplier < -CardView.Constants.movementDistance {
            deck.move(to: .left)
        } else if deck.storedActiveCardOffset.width*CardView.Constants.movementMultiplier > CardView.Constants.movementDistance {
            deck.move(to: .right)
        }
        deck.storedActiveCardOffset = .zero
    }
    
    private func onChangedAnimation(with dragGesture: DragGesture.Value) {
        if deck.validateDrag(dragGesture) {
            deck.storedActiveCardOffset = dragGesture.translation
        }
    }
    
    fileprivate func fullScreenOffset(for card: Card, with geometry: GeometryProxy) -> CGSize {
        return CGSize(width: (CGFloat(deck.index(of: card)-1) * geometry.size.width)-1 + deck.fullScreenActiveCardOffset.width, height: 0)
    }
    
    var body: some View {
        ZStack {
            if !showFullScreen {
                VStack {
                    ZStack {
                        ForEach(deck.cards) { card in
                            CardView(isFullScreen: false, card: card)
                                .matchedGeometryEffect(id: card.id, in: animation, isSource: true)
                                .transition(.scale(scale: CardView.Constants.scaleMultiplier))
                                .zIndex(deck.zIndex(of: card))
                                .offset(x: deck.offset(for: card).width, y: deck.offset(for: card).height)
                                .scaleEffect(x: deck.scale(of: card), y: deck.scale(of: card))
                                .rotationEffect(deck.rotation(for: card))
                                .gesture(
                                    DragGesture()
                                        .onChanged({ (drag) in
                                            withAnimation(.spring(response:0.6)) {
                                                onChangedAnimation(with: drag)
                                            }
                                        })
                                        .onEnded({ _ in
                                            withAnimation(.spring(response:0.6)) {
                                                onEndedAnimation()
                                            }
                                        })
                                )
                                .onTapGesture {
                                    showFullScreen.toggle()
                                }
                        }
                    }
                    Spacer(minLength: 400)
                }
            } else {
                GeometryReader { geometry in
                    NavigationView {
                        HStack {
                            ZStack {
                                ForEach(deck.cards) { card in
                                    CardView(isFullScreen: true, card: card)
                                        .navigationBarTitle("\(deck.activeCardIndex+1) of \(deck.cards.count)", displayMode: .inline)
                                        .navigationBarItems(
                                            leading:
                                                Button(action: {
                                                    showFullScreen.toggle()
                                                }, label: {
                                                    Text("Done").font(Font.body.weight(.semibold))
                                                }),
                                            trailing:
                                                Button {
                                                    showSheet.toggle()
                                                } label: {
                                                    Label("Share Product", systemImage: "square.and.arrow.up")
                                                })
                                        .navigationViewStyle(StackNavigationViewStyle())
                                        .navigationBarHidden(navBarHidden)
                                        .onTapGesture(perform: {
                                            withAnimation {
                                                UIScreen.main.focusedView?.window?.backgroundColor = .black
                                                navBarHidden.toggle()
                                            }
                                        })
                                        .matchedGeometryEffect(id: card.id, in: animation, isSource: true)
                                        .background(navBarHidden ? Color.black : Color.clear).edgesIgnoringSafeArea(.all)
                                        .offset(fullScreenOffset(for: card, with: geometry))
                                        .sheet(isPresented: $showSheet) {} content: {
                                            if let image = deck.activeCard?.image {
                                                ShareSheet(items: [image])
                                            }
                                        }
                                }
                            }
                            .onAppear {
                                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                                AppDelegate.orientationLock = .portrait
                            }.onDisappear {
                                AppDelegate.orientationLock = .all
                            }
                            .ignoresSafeArea()
                            .gesture(
                                DragGesture(minimumDistance: 0.0)
                                    .onChanged({ (drag) in
                                        if !(drag.translation.width < 0 && deck.activeCardIndex == deck.cards.count-1)
                                            && !(drag.translation.width > 0 && deck.activeCardIndex == 0) {
                                            withAnimation(.linear) {
                                                deck.fullScreenActiveCardOffset = drag.translation
                                            }
                                        }
                                    })
                                    .onEnded({ (drag) in
                                        withAnimation(.spring(response: 0.6)) {
                                            if abs(deck.fullScreenActiveCardOffset.width) > geometry.size.width*0.5 {
                                                if drag.translation.width > 0 {
                                                    deck.move(to: .right)
                                                } else {
                                                    deck.move(to: .left)
                                                }
                                            }
                                            deck.fullScreenActiveCardOffset = .zero
                                        }
                                    })
                            )
                            .offset(x: CGFloat(deck.activeCardIndex) * -geometry.size.width, y: 0)
                        }
                        .background(navBarHidden ? Color.black : Color.clear).ignoresSafeArea()
                    }
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    func makeCoordinator() -> () {}
}

struct CardView: View {
    
    enum Constants {
        static let greyColor: Color = .init(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1)
        static let radius: CGFloat = 11
        static let shadowY: CGFloat = 4
        static let shadowX: CGFloat = 0
        static let lineWidth: CGFloat = 0.5
        static let squareSide: CGFloat = 220
        static let movementDistance: CGFloat = squareSide * 0.6
        static let movementMultiplier: CGFloat = 1.5
        static let scaleMultiplier: CGFloat = 0.905
    }
    let isFullScreen: Bool
    let card: Card
    var body: some View {
        
        if !isFullScreen {
            RoundedRectangle(cornerRadius: Constants.radius, style: .continuous)
                .foregroundColor(.clear)
                .background(
                    Image(uiImage: card.image)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .frame(width: Constants.squareSide, height: Constants.squareSide)
                        .cornerRadius(Constants.radius)
                        .shadow(color: Constants.greyColor, radius: Constants.radius, x: Constants.shadowX, y: Constants.shadowY)
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.radius)
                                .stroke(Constants.greyColor, lineWidth: card.isEmptyCard ? 0 : Constants.lineWidth)
                        )
                )
                .transition(.identity)
                .animation(.spring(response:0.6))
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
