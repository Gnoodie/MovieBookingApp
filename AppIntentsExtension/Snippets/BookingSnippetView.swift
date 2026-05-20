import SwiftUI

@available(iOS 18.0, *)
struct BookingSnippetView: View {
    var movie: MovieEntity
    var cinema: CinemaEntity
    var showtime: ShowtimeEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Giả lập Poster phim
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 80)
                    .overlay(
                        Image(systemName: "film")
                            .foregroundColor(.blue)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(movie.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(movie.genre)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                    Text(cinema.name)
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                    Text("\(showtime.timeString) • \(showtime.format)")
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
