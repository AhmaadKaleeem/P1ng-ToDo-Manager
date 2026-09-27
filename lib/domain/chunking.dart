/// A byte range within a file for chunked upload.
class ChunkRange {
  const ChunkRange({
    required this.start,
    required this.end,
    required this.index,
  });
  final int start;
  final int end;
  final int index;
}

/// Pure. Splits [fileSize] into chunks of [chunkSize] bytes.
/// Unused in FR-02 but tested and seeded for the sync iteration.
List<ChunkRange> chunksFor(int fileSize,
    {int chunkSize = 5 * 1024 * 1024}) {
  if (fileSize <= 0) return const [];
  final chunks = <ChunkRange>[];
  var offset = 0;
  var index = 0;
  while (offset < fileSize) {
    final end = (offset + chunkSize).clamp(0, fileSize);
    chunks.add(ChunkRange(start: offset, end: end, index: index));
    offset = end;
    index++;
  }
  return chunks;
}
