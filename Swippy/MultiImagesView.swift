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
        self.rightCards = images.compactMap({ Card(image: $0) })
        self.activeCard = rightCards.first
    }
    
    // MARK: - Properties
    
    var fullScreenTopCardOffset: CGSize = .zero
    var topCardOffset: CGSize = .zero
    var activeCard: Card?
    
    var leftCards: [Card] = [
        .init(image: UIImage(), isEmptyCard: true)
    ]
    
    var rightCards: [Card]
    
    var cards: [Card] {
        let cards: [Card] = leftCards.reversed()+rightCards
        return cards.filter({ !$0.isEmptyCard })
    }
    
    
    // MARK: - Public API
    
    func position(of card: Card, in cards: [Card]) -> Int {
        guard let index = cards.firstIndex(of: card) else { return 0 }
        return index + 1
    }
    
}

// MARK: - Private API

private extension Deck {
    
    func validateDrag(_ drag: DragGesture.Value) -> Bool {
        let leftItemDraggingRight = activeCard == rightCards.first && leftCards.last?.isEmptyCard ?? false && drag.translation.width > 0
        let rightItemDraggingLeft = activeCard == rightCards.last && drag.translation.width < 0
        let outLimitsDrag = (abs(drag.translation.width/2) > CardView.Constants.movementDistance)
        return !(leftItemDraggingRight || rightItemDraggingLeft || outLimitsDrag)
    }
    
    func position(of card: Card?, from side: CardsSide) -> Int {
        guard let safeCard = card else { return 0 }
        switch side {
        case .left:
            return leftCards.firstIndex(of: safeCard) ?? 0
        case .right:
            return rightCards.firstIndex(of: safeCard) ?? 0
        }
    }
    
    func zIndex(of card: Card, from side: CardsSide) -> Double {
        
        enum zIndexPriority {
            static let high: Int = 99999
            static let medium: Int = 9999
            static let low: Int = 999
        }
        
        
        
        if card == activeCard { return Double(zIndexPriority.medium) }
        
        if isDistantEnoughToSwipe() {
            if topCardOffset.width > 0 && leftCards[1] == card  {
                return Double(zIndexPriority.high)
                
            } else if topCardOffset.width < 0 && position(of: card, from: .right) == position(of: activeCard, from: .right)+1 {
                return Double(zIndexPriority.high)
            }
        }
        
        
        var rightAditionalIndex = 0
        var leftAditionalIndex = 0
        
        if topCardOffset.width < 0 {
            leftAditionalIndex = -zIndexPriority.low
        } else {
            rightAditionalIndex = -zIndexPriority.low
        }
        
        switch side {
        case .right:
            return Double(rightCards.count - position(of: card, from: .right) + rightAditionalIndex)
        case .left:
            return Double(leftCards.count - position(of: card, from: .left) + leftAditionalIndex)
        }
    }
    
    func scale(of card: Card, from side: CardsSide) -> CGFloat {
        if card == activeCard {
            let calculatedScale = abs((1 - abs(topCardOffset.width*CardView.Constants.movementMultiplier/2)/CardView.Constants.movementDistance))
            if isDistantEnoughToSwipe() {
                return 1 - calculatedScale
            } else {
                return calculatedScale
            }
        } else {
            
            func scaleForPosition(_ position: Double) -> CGFloat {
                let decimalScale = pow(CardView.Constants.scaleMultiplier, position)
                let doubleScale = NSDecimalNumber(decimal: Decimal(decimalScale)).doubleValue
                let finalScale = CGFloat(doubleScale)
                return finalScale
            }
            
            let cardPosition = CGFloat(position(of: card, from: side))
            let percentageMovement = abs(topCardOffset.width) < CardView.Constants.movementDistance ? abs(topCardOffset.width) / CardView.Constants.movementDistance : 1
            
            if topCardOffset.width > 0 {
                switch side {
                case .left:
                    return scaleForPosition(cardPosition-percentageMovement)
                case .right:
                    return scaleForPosition(cardPosition+percentageMovement)
                }
            } else {
                switch side {
                case .left:
                    return scaleForPosition(cardPosition+percentageMovement)
                case .right:
                    return scaleForPosition(cardPosition-percentageMovement)
                }
            }
        }
    }
    
    func offset(for card: Card, from side: CardsSide) -> CGSize {
        if card != activeCard { return CGSize(width: backCardsOffset(of: card, from: side), height: 0) }
        if isDistantEnoughToSwipe() {
            let finalOffSideWidth = getWidthCompensatingExtraMovement()
            let finalOffSideHeight = -abs(finalOffSideWidth/CardView.Constants.movementMultiplier)*0.4
            return CGSize(width: finalOffSideWidth, height: finalOffSideHeight)
        } else {
            return CGSize(width: topCardOffset.width*CardView.Constants.movementMultiplier, height: -abs(topCardOffset.width)*0.4)
        }
    }
    
    func backCardsOffset(of card: Card, from side: CardsSide) -> CGFloat {
        let deckPosition =  CGFloat(position(of: card, from: side))
        let offSetMultiplier = CardView.Constants.squareSide / 8
        let offset = deckPosition * offSetMultiplier
        let percentageMovement = abs(topCardOffset.width) < CardView.Constants.movementDistance ? abs(topCardOffset.width) / CardView.Constants.movementDistance : 1
        if topCardOffset.width > 0 {
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
    
    func rotation(for card: Card, from side: CardsSide) -> Angle {
        if card != activeCard {
            
            func rotationForAboveCard(_ card: Card, _ side: CardsSide, _ degrees: Angle, _ percentageMovement: CGFloat) -> Angle {
                let aboveDegrees = Angle.degrees(-Double(position(of: card, from: side)+1)*3)
                let finalDegrees = degrees + ((degrees-aboveDegrees)*percentageMovement)
                return finalDegrees
            }
            
            func rotationForBehindCard(_ card: Card, _ side: CardsSide, _ degrees: Angle, _ percentageMovement: CGFloat) -> Angle {
                let behindDegrees = Angle.degrees(-Double(position(of: card, from: side)-1)*3)
                let finalDegrees = degrees - ((behindDegrees-degrees)*percentageMovement)
                return finalDegrees
            }
            
            let percentageMovement = abs(topCardOffset.width) < CardView.Constants.movementDistance ? abs(topCardOffset.width) / CardView.Constants.movementDistance : 1
            let degrees = Angle.degrees(-Double(position(of: card, from: side))*3)
            
            if topCardOffset.width > 0 {
                switch side {
                case .left:
                    return rotationForAboveCard(card, side, degrees, percentageMovement)
                case .right:
                    return rotationForBehindCard(card, side, degrees, percentageMovement)
                }
            } else {
                switch side {
                case .left:
                    return rotationForBehindCard(card, side, degrees, percentageMovement)
                case .right:
                    return rotationForAboveCard(card, side, degrees, percentageMovement)
                }
            }
        }
        
        return activeCardRotation(for: card, offset: topCardOffset)
    }
    
    func activeCardRotation(for card: Card, offset: CGSize = .zero) -> Angle {
        if isDistantEnoughToSwipe() {
            return .degrees(-Double(getWidthCompensatingExtraMovement()/CardView.Constants.movementMultiplier) / 10)
        } else {
            return .degrees(-Double(offset.width) / 10)
        }
        
    }
    
    func isDistantEnoughToSwipe(_ distance: CGFloat? = nil) -> Bool {
        let actualDistance = distance ?? topCardOffset.width*CardView.Constants.movementMultiplier
        return abs(actualDistance) > CardView.Constants.movementDistance
    }
    
    func getWidthCompensatingExtraMovement() -> CGFloat {
        let calculatedOffSetWidth = topCardOffset.width*CardView.Constants.movementMultiplier
        let extraOffSideWidth = abs(calculatedOffSetWidth) - CardView.Constants.movementDistance
        if extraOffSideWidth > CardView.Constants.movementDistance { return 0 }
        let finalOffSideWidth = CardView.Constants.movementDistance - extraOffSideWidth
        return calculatedOffSetWidth > 0 ? finalOffSideWidth : -finalOffSideWidth
    }
}

// MARK: - Mutating API

extension Deck {
    mutating func moveToRight() {
        if leftCards.count > 1 {
            let leftCardMoving = leftCards.remove(at: 1)
            rightCards.insert(leftCardMoving, at: 0)
        }
        updateActiveCard()
    }
    
    mutating func moveToLeft() {
        if rightCards.count > 1 {
            let rightCardMoving = rightCards.remove(at: 0)
            leftCards.insert(rightCardMoving, at: 1)
        }
        updateActiveCard()
    }
    
    mutating func updateActiveCard() {
        if let card = rightCards.first {
            activeCard = card
        }
        topCardOffset = .zero
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
    let coloredNavAppearance = UINavigationBarAppearance()
    
    init(with images: [UIImage]) {
        coloredNavAppearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = coloredNavAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredNavAppearance
        _deck = State(initialValue: Deck(with: images))
    }
    
    private func onEndedAnimation() {
        if deck.topCardOffset.width*CardView.Constants.movementMultiplier < -CardView.Constants.movementDistance {
            deck.moveToLeft()
        } else if deck.topCardOffset.width*CardView.Constants.movementMultiplier > CardView.Constants.movementDistance {
            deck.moveToRight()
        }
        deck.topCardOffset = .zero
    }
    
    private func onChangedAnimation(with dragGesture: DragGesture.Value) {
        if deck.validateDrag(dragGesture) {
            deck.topCardOffset = dragGesture.translation
        }
    }
    
    private func updateFullscreenIndex() {
        if let activeCard = deck.activeCard {
            fullScreenIndex = deck.position(of: activeCard, in: deck.cards)-1
        }
    }
    
    var body: some View {
        ZStack {
            if !showFullScreen {
                VStack {
                    ZStack {
                        ForEach(deck.leftCards) { card in
                            if card != deck.rightCards.first {
                                CardView(isFullScreen: false, card: card)
                                    .matchedGeometryEffect(id: card.id, in: animation, isSource: true)
                                    .transition(.scale(scale: CardView.Constants.scaleMultiplier))
                                    .zIndex(deck.zIndex(of: card, from: .left))
                                    .offset(x: deck.offset(for: card, from: .left).width, y: deck.offset(for: card, from: .left).height)
                                    .scaleEffect(x: deck.scale(of: card, from: .left), y: deck.scale(of: card, from: .left))
                                    .rotationEffect(deck.rotation(for: card, from: .left))
                            } else {
                                CardView(isFullScreen: false, card: card)
                                    .matchedGeometryEffect(id: card.id, in: animation, isSource: true)
                                    .transition(.scale(scale: CardView.Constants.scaleMultiplier))
                            }
                        }
                        ForEach(deck.rightCards) { card in
                            CardView(isFullScreen: false, card: card)
                                .matchedGeometryEffect(id: card.id, in: animation, isSource: true)
                                .transition(.scale(scale: CardView.Constants.scaleMultiplier))
                                .zIndex(deck.zIndex(of: card, from: .right))
                                .offset(x: deck.offset(for: card, from: .right).width, y: deck.offset(for: card, from: .right).height)
                                .scaleEffect(x: deck.scale(of: card, from: .right), y: deck.scale(of: card, from: .right))
                                .rotationEffect(-deck.rotation(for: card, from: .right))
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
                                            updateFullscreenIndex()
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
                        ZStack {
                            ForEach(deck.cards) { card in
                                CardView(isFullScreen: true, card: card)
                                    .navigationBarTitle("\(fullScreenIndex+1) of \(deck.cards.count)", displayMode: .inline)
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
                                    .offset(CGSize(width: (CGFloat(deck.position(of: card, in: deck.cards)-1) * geometry.size.width)  + deck.fullScreenTopCardOffset.width, height: 0))
                                    .sheet(isPresented: $showSheet) {} content: {
                                        if let image = deck.rightCards.first?.image {
                                            ShareSheet(items: [image])
                                        }
                                    }
                            }
                        }
                        .onAppear {
                            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation") // Forcing the rotation to portrait
                            AppDelegate.orientationLock = .portrait // And making sure it stays that way
                        }.onDisappear {
                            AppDelegate.orientationLock = .all // Unlocking the rotation when leaving the view
                        }
                        .ignoresSafeArea()
                        .gesture(
                            DragGesture(minimumDistance: 0.0)
                                .onChanged({ (drag) in
                                    if !(drag.translation.width < 0 && fullScreenIndex == deck.cards.count-1)
                                        && !(drag.translation.width > 0 && fullScreenIndex == 0) {
                                        withAnimation(.linear) {
                                            deck.fullScreenTopCardOffset = drag.translation
                                        }
                                    }
                                })
                                .onEnded({ (drag) in
                                    withAnimation(.spring(response: 0.6)) {
                                        if abs(deck.fullScreenTopCardOffset.width) > geometry.size.width*0.5 {
                                            if drag.translation.width > 0 {
                                                deck.moveToRight()
                                                fullScreenIndex = fullScreenIndex-1
                                            } else {
                                                deck.moveToLeft()
                                                fullScreenIndex = fullScreenIndex+1
                                            }
                                        }
                                        deck.fullScreenTopCardOffset = .zero
                                    }
                                })
                        )
                        .offset(x: CGFloat(fullScreenIndex) * -geometry.size.width, y: 0)
                    }
                }
            }
        }
    }
    
    
    
    @State var navBarHidden: Bool = false
    @State private var fullScreenIndex: Int = 0
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
