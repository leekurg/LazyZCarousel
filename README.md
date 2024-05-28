# LazyZCarousel
Infinite swipable paged view with on-demand page loading for  **iOS 14 and higher**.

<p align="center">
<img width="361" alt="LazyZCarousel sample" src="https://github.com/leekurg/NavigationViewElastic/assets/105886145/275e5d77-2567-464e-aa34-7f7d7fd199ad">
</p>

### Overview
**LazyZCarousel** is an ideal component for displaying large sets of data in a paginated form. 
This component allows for smooth swiping through content until the end is reached, providing a seamless user experience. 
It ensures high performance by only storing the page layout closure and the data for the current page, 
unlike some platform's **Lazy** containers. 
Additionally, **LazyZCarousel** offers a paging API compatible with **iOS 14 and higher**, 
unlike the **ScrollView** paging API which is available only from **iOS 17**.

### Details
**LazyZCarousel** is built using a **ZStack** with offsets for the current, next, and previous pages. 
You can provide an initial piece of data and a page layout using a **ViewBuilder** closure. 
The component handles situations with nullable data by displaying placeholders for the next and previous pages if they exist. 
When the current page is displayed, **LazyZCarousel** checks for the existence of the next and previous pages. 
If they exist, placeholders are shown with animations. After a swipe to another page is completed, 
the current page data is updated and checks for the next/previous pages are performed again.

You can adjust the width ratio occupied by the page content within the range **[0.1, 1]**. 
The default value is **0.7**, meaning that the page content will occupy **70%** of the available width.

### Limitations
The infinite nature of **LazyZCarousel** is based on manipulating offsets with or without animations. 
Therefore, the identity of the page’s **View** should be loose when data changes. This means that the page 
layout and the placeholder layout (when **data** is nil) are supposed to look similar to maintain a consistent appearance.

### Install
`SPM` installation: in **Xcode** tap «**File → Add packages…**», paste is search field the URL of this page and press «**Add package**».

### Usage
Annotate `SwiftUI` file with «**import LazyZCarousel**». Then pass to **LazyZCarousel** a piece of data to present and a page layout closure:

```
struct ExampleView: View {
    @State var currentPageData: MyData

    var body: some View {
        LazyZCarousel(data: currentPageData, contentHRatio: 0.6) { data in
            // Your page layout here
        } isNextAvailable: {
            // Logic to determine if next data is available
        } fetchNext: { nextFromId in
            // Logic to fetch next data
        } isPrevAvailable: {
            // Logic to determine if previous data is available
        } fetchPrev: { prevFromId in
            // Logic to fetch previous data
        }
    }
}
```
