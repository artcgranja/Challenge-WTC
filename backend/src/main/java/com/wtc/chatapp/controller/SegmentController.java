package com.wtc.chatapp.controller;

import com.wtc.chatapp.dto.SegmentRequest;
import com.wtc.chatapp.model.Segment;
import com.wtc.chatapp.service.SegmentService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/segments")
public class SegmentController {

    private final SegmentService segmentService;

    public SegmentController(SegmentService segmentService) {
        this.segmentService = segmentService;
    }

    @GetMapping
    public ResponseEntity<List<Segment>> list() {
        return ResponseEntity.ok(segmentService.list());
    }

    @PostMapping
    public ResponseEntity<Segment> create(@Valid @RequestBody SegmentRequest request) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getPrincipal().toString();
        return ResponseEntity.status(HttpStatus.CREATED).body(segmentService.create(request, userId));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Segment> update(@PathVariable String id, @Valid @RequestBody SegmentRequest request) {
        return ResponseEntity.ok(segmentService.update(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        segmentService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
