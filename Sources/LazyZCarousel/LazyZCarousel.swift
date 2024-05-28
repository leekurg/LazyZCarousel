//
//  LazyZCarousel.swift
//
//
//  Created by Илья Аникин on 24.05.2024.
//

import SwiftUI

fileprivate let NSEC_PER_SEC: Double = 1_000_000_000

/// A carousel paging view with lazy page loading.
///
/// This view allows swiping through pages of lazily loaded data using swipe gestures.
/// Provide an initial piece of **data** and a page layout with the **content()** closure.
/// Define actions to change the **data** after a swipe is performed using the **fetchNext()**
/// and **fetchPrev()** closures.
/// Use the **isNextAvailable()** and **isPrevAvailable()** closures to determine
/// whether there is a next or previous page available.
///
/// You can adjust the width ratio occupied by the content using the **contentHRatio** parameter,
/// which accepts values in the range [0.1, 1].
/// The default width ratio is **0.7**, meaning the content will occupy **70%** of the available width.
///
/// - Parameters:
///   - data: The currently displayed piece of data.
///   - contentHRatio: The width ratio occupied by the content.
///   - content: The layout for each page.
///   - isNextAvailable: A closure that determines if there is a next piece of data available.
///   Triggered after the **data** changes.
///   - fetchNext: A closure to fetch the next piece of data. Triggered after the swipe animation has finished.
///   - isPrevAvailable: A closure that determines if there is a previous piece of data available.
///   Triggered after the **data** changes.
///   - fetchPrev: A closure to fetch the previous piece of data. Triggered after the swipe animation has finished.
///
public struct LazyZCarousel<T: Equatable, Content: View>: View {
    private let data: T?
    private let contentHRatio: Double
    private let content: (T?) -> Content
    private let isNextAvailable: () -> Bool
    private let fetchNext: (T) -> Void
    private let isPrevAvailable: () -> Bool
    private let fetchPrev: (T) -> Void

    public init(
        data: T?,
        contentHRatio: Double = 0.7,
        @ViewBuilder content: @escaping (T?) -> Content,
        isNextAvailable: @escaping () -> Bool,
        fetchNext: @escaping (T) -> Void,
        isPrevAvailable: @escaping () -> Bool,
        fetchPrev: @escaping (T) -> Void
    ) {
        self.data = data
        self.contentHRatio = max(0.1, min(1, contentHRatio))
        self.content = content
        self.isNextAvailable = isNextAvailable
        self.fetchNext = fetchNext
        self.isPrevAvailable = isPrevAvailable
        self.fetchPrev = fetchPrev

        self._dragState = GestureState(
            initialValue: .zero,
            resetTransaction: .init(animation: .bouncy)
        )
    }

    @GestureState private var dragState: CGFloat
    @State private var swipedTo: SwipeDirection? = nil
    @State private var isNext = false
    @State private var isPrev = false
    @State private var isInSwiping = false
    @State private var isDataFrozen = true
    @State private var offset: CGFloat = .zero
    @State private var offsetNext: CGFloat = Self.offsetOut
    @State private var offsetPrev: CGFloat = -Self.offsetOut
    @State private var offsetNextAbsent: CGFloat = .zero

    private let animation: Animation = .spring(duration: 0.4)
    private let animationDuration: TimeInterval = 0.4
    private static var offsetOut: CGFloat { 1000 }

    public var body: some View {
        GeometryReader { gm in
            let itemWidth = gm.size.width * contentHRatio
            let itemSpacing = gm.size.width * (1 - contentHRatio) / 2
            let pageWidth = itemWidth + itemSpacing / 2
            let dragThreshold = itemWidth / 3

            ZStack(alignment: .center) {
                content(isDataFrozen ? data : nil)
                    .frame(width: itemWidth)
                    .contentShape(Rectangle())
                    .offset(x: offset + dragState)

                if isNext {
                    content(nil)
                        .frame(width: itemWidth)
                        .contentShape(Rectangle())
                        .offset(x: offset + dragState + offsetNext)
                }

                if isPrev {
                    content(nil)
                        .frame(width: itemWidth)
                        .contentShape(Rectangle())
                        .offset(x: offset + dragState + offsetPrev)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture()
                    .updating($dragState) { value, state, _ in
                        withAnimation(.interactiveSpring) {
                            if !isNext, value.translation.width < 0 {
                                state = value.translation.width / 3
                            } else if !isPrev, value.translation.width > 0 {
                                state = value.translation.width / 3
                            }
                        }
                    }
                    .onChanged { gestureValue in
                        guard !isInSwiping else { return }

                        if gestureValue.translation.width < -dragThreshold && isNext {
                            isInSwiping = true
                            swipedTo = .next

                            withAnimation(animation) {
                                offset = -pageWidth
                                offsetNext = pageWidth
                                offsetPrev = -pageWidth
                            }

                            if let data {
                                Task {
                                    try await Task.sleep(nanoseconds: UInt64((animationDuration + 0.1) * NSEC_PER_SEC))
                                    isDataFrozen = false
                                    fetchNext(data)
                                }
                            }

                            return
                        } else if gestureValue.translation.width > dragThreshold && isPrev {
                            isInSwiping = true
                            swipedTo = .previous

                            withAnimation(animation) {
                                offset = pageWidth
                                offsetNext = pageWidth
                                offsetPrev = -pageWidth
                            }

                            if let data {
                                Task {
                                    try await Task.sleep(nanoseconds: UInt64((animationDuration + 0.1) * NSEC_PER_SEC))
                                    isDataFrozen = false
                                    fetchPrev(data)
                                }
                            }
                        }
                    }
            )
            .onChange(of: data) { _ in
                isInSwiping = false
                isDataFrozen = true
                offset = .zero

                switch swipedTo {
                case .next: offsetNext = Self.offsetOut
                case .previous: offsetPrev = -Self.offsetOut
                case nil: break
                }

                isNext = isNextAvailable()
                if isNext { withAnimation(animation) { offsetNext = pageWidth } }

                isPrev = isPrevAvailable()
                if isPrev { withAnimation(animation) { offsetPrev = -pageWidth } }
            }
            .onAppear {
                isNext = isNextAvailable()
                if isNext { withAnimation(animation) { offsetNext = pageWidth } }

                isPrev = isPrevAvailable()
                if isPrev { withAnimation(animation) { offsetPrev = -pageWidth } }
            }
        }
        .clipped()
    }
}

public extension LazyZCarousel {
    init(
        data: T?,
        contentHRatio: Double = 0.7,
        isNextAvailable: Bool,
        fetchNext: @escaping () -> Void,
        isPrevAvailable: Bool,
        fetchPrev: @escaping () -> Void,
        @ViewBuilder content: @escaping (T?) -> Content
    ) {
        self.data = data
        self.contentHRatio = max(0.1, min(1, contentHRatio))
        self.content = content
        self.isNextAvailable = { isNextAvailable }
        self.fetchNext = { _ in fetchNext() }
        self.isPrevAvailable = { isPrevAvailable }
        self.fetchPrev = { _ in fetchPrev() }

        self._dragState = GestureState(
            initialValue: .zero,
            resetTransaction: .init(animation: .bouncy)
        )
    }
}

enum SwipeDirection {
    case previous
    case next
}

fileprivate struct ProxyView: View {
    @State var data: Int = 5

    var body: some View {
        ScrollView(.vertical) {
            LazyZCarousel(data: data, contentHRatio: 0.6) { data in
                Group {
                    if let data {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.blue)
                            .overlay(
                                Text("\(data)")
                                    .font(.title)
                                    .foregroundColor(.white)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.gray)
                    }
                }
            } isNextAvailable: {
                data < 10
            } fetchNext: { nextFromId in
                print("fetched next")
                data += 1
            } isPrevAvailable: {
                data > 0
            } fetchPrev: { prevFromId in
                print("fetched prev")
                data -= 1
            }
            .border(.red)
            .frame(height: 300)
            .padding(.horizontal)
            .padding(.top, 150)
        }
    }
}

#Preview {
    ProxyView()
}
