import SwiftUI

struct SegmentPickerView: View {
    let segments: [Segment]
    @Binding var selectedSegment: Segment?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(segments) { segment in
                Button(action: {
                    selectedSegment = segment
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(segment.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            if let description = segment.description {
                                Text(description)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            HStack(spacing: 4) {
                                ForEach(segment.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Theme.primary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Theme.primary.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        Spacer()
                        if selectedSegment?.id == segment.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(Theme.primary)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
            }
            .navigationTitle("Selecionar Segmento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}
