package com.wtc.chatapp.controller;

import com.wtc.chatapp.model.Notification;
import com.wtc.chatapp.service.NotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping
    public ResponseEntity<List<Notification>> list() {
        String userId = SecurityContextHolder.getContext().getAuthentication().getPrincipal().toString();
        return ResponseEntity.ok(notificationService.getByUserId(userId));
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<Void> markAsRead(@PathVariable String id) {
        notificationService.markAsRead(id);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/read-all")
    public ResponseEntity<Void> markAllAsRead() {
        String userId = SecurityContextHolder.getContext().getAuthentication().getPrincipal().toString();
        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok().build();
    }
}
