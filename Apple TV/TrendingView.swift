import SwiftUI

struct TrendingView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var trendingState: TrendingState

    @Binding var tabSelection: TabSelection

    @ObservedObject private var videosProvider = TrendingVideosProvider()

    @State private var selectingCategory = false
    @State private var selectingCountry = false

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .top) {
                    Spacer()

                    categoryButton
                    countryFlag
                    countryButton

                    Spacer()
                }
                .scaleEffect(0.85)

                VideosView(tabSelection: $tabSelection, videos: videos)
            }
        }
    }

    var videos: [Video] {
        videosProvider.load(category: trendingState.category, country: trendingState.country)

        return videosProvider.videos
    }

    var categoryButton: some View {
        Button(trendingState.category.name) {
            trendingState.category = trendingState.category.next()
        }
        .contextMenu {
            ForEach(TrendingCategory.allCases) { category in
                Button(category.name) {
                    trendingState.category = category
                }
            }
        }
    }

    var countryFlag: some View {
        Text(trendingState.country.flag)
            .font(.system(size: 60))
    }

    var countryButton: some View {
        Button(trendingState.country.rawValue) {
            selectingCountry.toggle()
        }
        .fullScreenCover(isPresented: $selectingCountry) {
            TrendingCountrySelectionView(selectedCountry: $trendingState.country)
        }
    }
}
