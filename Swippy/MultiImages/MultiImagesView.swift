//
//  MultiImagesView.swift
//  swippy
//
//  Created by João Pedro Giarrante on 22/07/21.
//

import SwiftUI

struct MultiImagesView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = MultiImagesView.ViewModel(
            leftNavigationButtonText: "Done",
            rightNavigationButtonText: "Share Product",
            rightNavigationButtonImage: "square.and.arrow.up",
            topNavigationText: "%@ of %@",
            images:  [#imageLiteral(resourceName: "Image1"), #imageLiteral(resourceName: "Image2"), #imageLiteral(resourceName: "Image1"), #imageLiteral(resourceName: "Image2"), #imageLiteral(resourceName: "Image1")],
            squareSide: 220)
        MultiImagesView(with: viewModel)
    }
}

// MARK: - MultiImagesView

struct MultiImagesView: View {
    
    // MARK: - Static Constants
    
    enum Constants {
        static let greyColor: Color = .init(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1)
        static let radius: CGFloat = 11
        static let shadowY: CGFloat = 4
        static let shadowX: CGFloat = 0
        static let lineWidth: CGFloat = 0.5
        static let animation: Animation = .spring(response:0.6)
        static let scaleMultiplier: CGFloat = 0.905
        static let movementMultiplier: CGFloat = 1.5
    }
    
    // MARK: - Private Properties
    
    @Namespace private var animation
    @State private var showSheet = false
    @State private var navBarHidden = false
    @State private var showFullScreen = false
    @State private var deck: MultiImagesDeck
    private let viewModel: ViewModel
    private let coloredNavAppearance = UINavigationBarAppearance()
    
    
    // MARK: - Initializer
    
    init(with viewModel: ViewModel) {
        self.viewModel = viewModel
        _deck = State(initialValue: MultiImagesDeck(images: viewModel.images, squareSide: viewModel.squareSide))
        
        // Navigation Bar
        coloredNavAppearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = coloredNavAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredNavAppearance
    }
    
    // MARK: - ViewModel
    
    struct ViewModel {
        let leftNavigationButtonText: String
        let rightNavigationButtonText: String
        let rightNavigationButtonImage: String
        let topNavigationText: String
        let images: [UIImage]
        let squareSide: CGFloat
    }
    
    // MARK: - Public Properties
    
    var body: some View {
        ZStack {
            if !showFullScreen {
                ZStack {
                    ForEach(deck.cards) { card in
                        MultiImagesCardView(isFullScreen: false, card: card, squareSide: viewModel.squareSide)
                            .matchedGeometryEffect(id: card.id, in: animation, isSource: true)
                            .transition(.scale(scale: MultiImagesView.Constants.scaleMultiplier))
                            .zIndex(deck.zIndex(of: card))
                            .offset(x: deck.offset(for: card).width, y: deck.offset(for: card).height)
                            .scaleEffect(x: deck.scale(of: card), y: deck.scale(of: card))
                            .rotationEffect(deck.rotation(for: card))
                            .gesture(
                                DragGesture()
                                    .onChanged({ (drag) in
                                        withAnimation(MultiImagesView.Constants.animation) {
                                            deck.onChangedAnimation(with: drag)
                                        }
                                    })
                                    .onEnded({ _ in
                                        withAnimation(MultiImagesView.Constants.animation) {
                                            deck.onEndedAnimation()
                                        }
                                    })
                            )
                            .onTapGesture {
                                showFullScreen.toggle()
                            }
                    }
                }
            } else {
                GeometryReader { geometry in
                    NavigationView {
                        HStack {
                            ZStack {
                                ForEach(deck.cards) { card in
                                    MultiImagesCardView(isFullScreen: true, card: card, squareSide: viewModel.squareSide)
                                        .navigationBarTitle(String(format: viewModel.topNavigationText, String(deck.activeCardIndex+1), String(deck.cards.count)), displayMode: .inline)
                                        .navigationBarItems(
                                            leading:
                                                Button(action: {
                                                    showFullScreen.toggle()
                                                }, label: {
                                                    Text(viewModel.leftNavigationButtonText).font(Font.body.weight(.semibold))
                                                }),
                                            trailing:
                                                Button {
                                                    showSheet.toggle()
                                                } label: {
                                                    Label(viewModel.rightNavigationButtonText, systemImage: viewModel.rightNavigationButtonImage)
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
                                        .offset(deck.fullScreenOffset(for: card, with: geometry))
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
                                                deck.onChangedFullscreenAnimation(with: drag)
                                            }
                                        }
                                    })
                                    .onEnded({ (drag) in
                                        withAnimation(.spring(response: 0.6)) {
                                            deck.onEndedFullscreenAnimation(drag: drag, geometry: geometry)
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
