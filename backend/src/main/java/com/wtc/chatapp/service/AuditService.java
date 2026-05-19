package com.wtc.chatapp.service;

import com.wtc.chatapp.model.AuditLog;
import com.wtc.chatapp.repository.AuditLogRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AuditService {

    private final AuditLogRepository auditLogRepository;

    public AuditService(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    public void log(String userId, String action, String resource, String resourceId, String details, String ipAddress) {
        AuditLog log = AuditLog.builder()
                .userId(userId)
                .action(action)
                .resource(resource)
                .resourceId(resourceId)
                .details(details)
                .ipAddress(ipAddress)
                .build();
        auditLogRepository.save(log);
    }

    public List<AuditLog> list(String resource, String userId) {
        if (resource != null) {
            return auditLogRepository.findByResourceOrderByTimestampDesc(resource);
        }
        if (userId != null) {
            return auditLogRepository.findByUserIdOrderByTimestampDesc(userId);
        }
        return auditLogRepository.findAllByOrderByTimestampDesc();
    }
}
