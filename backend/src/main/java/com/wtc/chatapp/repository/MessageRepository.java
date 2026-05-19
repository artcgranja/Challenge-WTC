package com.wtc.chatapp.repository;

import com.wtc.chatapp.model.Message;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;

import java.util.List;

public interface MessageRepository extends MongoRepository<Message, String> {

    List<Message> findByRecipientIdOrderByCreatedAtDesc(String recipientId);

    List<Message> findBySenderIdOrderByCreatedAtDesc(String senderId);

    @Query("{ '$or': [ { 'recipientId': ?0 }, { 'segmentTags': { '$in': ?1 } } ] }")
    List<Message> findInbox(String userId, List<String> tags, Sort sort);
}
