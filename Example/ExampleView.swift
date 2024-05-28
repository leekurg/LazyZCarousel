//
//  File.swift
//  
//
//  Created by Илья Аникин on 28.05.2024.
//

import SwiftUI

struct ExampleView: View {
    @State var currentPageData: Int = 5

    var body: some View {
        ScrollView(.vertical) {
            LazyZCarousel(data: currentPageData, contentHRatio: 0.6) { data in
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
                currentPageData < 10
            } fetchNext: { nextFromId in
                currentPageData += 1
            } isPrevAvailable: {
                currentPageData > 0
            } fetchPrev: { prevFromId in
                currentPageData -= 1
            }
            .border(.red)
            .frame(height: 300)
            .padding(.top, 150)
        }
    }
}
