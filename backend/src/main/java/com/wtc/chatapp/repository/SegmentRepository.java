package com.wtc.chatapp.repository;

import com.wtc.chatapp.model.Segment;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface SegmentRepository extends MongoRepository<Segment, String> {
    List<Segment> findByTagsContaining(String tag);
}
