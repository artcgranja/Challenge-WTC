package com.wtc.chatapp.controller;

import com.wtc.chatapp.model.AuditLog;
import com.wtc.chatapp.service.AuditService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/audit-logs")
public class AuditLogController {

    private final AuditService auditService;

    public AuditLogController(AuditService auditService) {
        this.auditService = auditService;
    }

    @GetMapping
    public ResponseEntity<List<AuditLog>> list(
            @RequestParam(required = false) String resource,
            @RequestParam(required = false) String userId) {
        return ResponseEntity.ok(auditService.list(resource, userId));
    }
}
