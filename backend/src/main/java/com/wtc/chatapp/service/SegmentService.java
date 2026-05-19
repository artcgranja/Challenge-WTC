package com.wtc.chatapp.service;

import com.wtc.chatapp.dto.SegmentRequest;
import com.wtc.chatapp.model.Segment;
import com.wtc.chatapp.repository.SegmentRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;

@Service
public class SegmentService {

    private final SegmentRepository segmentRepository;

    public SegmentService(SegmentRepository segmentRepository) {
        this.segmentRepository = segmentRepository;
    }

    public List<Segment> list() {
        return segmentRepository.findAll();
    }

    public Segment getById(String id) {
        return segmentRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Segment not found"));
    }

    public Segment create(SegmentRequest request, String createdBy) {
        Segment segment = Segment.builder()
                .name(request.getName())
                .description(request.getDescription())
                .tags(request.getTags())
                .createdBy(createdBy)
                .build();
        return segmentRepository.save(segment);
    }

    public Segment update(String id, SegmentRequest request) {
        Segment segment = getById(id);
        segment.setName(request.getName());
        segment.setDescription(request.getDescription());
        segment.setTags(request.getTags());
        segment.setUpdatedAt(Instant.now());
        return segmentRepository.save(segment);
    }

    public void delete(String id) {
        segmentRepository.deleteById(id);
    }
}
