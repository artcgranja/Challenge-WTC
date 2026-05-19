package com.wtc.chatapp.controller;

import com.wtc.chatapp.dto.MessageRequest;
import com.wtc.chatapp.model.Message;
import com.wtc.chatapp.service.MessageService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class MessageController {

    private final MessageService messageService;

    public MessageController(MessageService messageService) {
        this.messageService = messageService;
    }

    @PostMapping("/messages")
    public ResponseEntity<Message> send(@Valid @RequestBody MessageRequest request) {
        String senderId = SecurityContextHolder.getContext().getAuthentication().getPrincipal().toString();
        return ResponseEntity.status(HttpStatus.CREATED).body(messageService.sendMessage(request, senderId));
    }

    @GetMapping("/messages/{id}")
    public ResponseEntity<Message> get(@PathVariable String id) {
        return ResponseEntity.ok(messageService.getById(id));
    }

    @GetMapping("/inbox/{customerId}")
    public ResponseEntity<List<Message>> inbox(@PathVariable String customerId) {
        return ResponseEntity.ok(messageService.getInbox(customerId));
    }

    @PutMapping("/messages/{id}/read")
    public ResponseEntity<Message> markAsRead(@PathVariable String id) {
        return ResponseEntity.ok(messageService.markAsRead(id));
    }

    @PutMapping("/messages/{id}/star")
    public ResponseEntity<Message> toggleStar(@PathVariable String id) {
        return ResponseEntity.ok(messageService.toggleStar(id));
    }

    @GetMapping("/messages/sent/{senderId}")
    public ResponseEntity<List<Message>> getSentMessages(@PathVariable String senderId) {
        return ResponseEntity.ok(messageService.getSentMessages(senderId));
    }
}
