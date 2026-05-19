package com.wtc.chatapp.repository;

import com.wtc.chatapp.model.AuditLog;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface AuditLogRepository extends MongoRepository<AuditLog, String> {
    List<AuditLog> findByResourceOrderByTimestampDesc(String resource);
    List<AuditLog> findByUserIdOrderByTimestampDesc(String userId);
    List<AuditLog> findAllByOrderByTimestampDesc();
}
