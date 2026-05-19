package com.wtc.chatapp.controller;

import com.wtc.chatapp.dto.CustomerRequest;
import com.wtc.chatapp.dto.NoteRequest;
import com.wtc.chatapp.model.Customer;
import com.wtc.chatapp.service.CustomerService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/customers")
public class CustomerController {

    private final CustomerService customerService;

    public CustomerController(CustomerService customerService) {
        this.customerService = customerService;
    }

    @GetMapping
    public ResponseEntity<List<Customer>> list(
            @RequestParam(required = false) String tag,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) Integer minScore) {
        return ResponseEntity.ok(customerService.list(tag, status, minScore));
    }

    @PostMapping
    public ResponseEntity<Customer> create(@Valid @RequestBody CustomerRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(customerService.create(request));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Customer> get(@PathVariable String id) {
        return ResponseEntity.ok(customerService.getById(id));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Customer> update(@PathVariable String id, @Valid @RequestBody CustomerRequest request) {
        return ResponseEntity.ok(customerService.update(id, request));
    }

    @GetMapping("/{id}/timeline")
    public ResponseEntity<Map<String, Object>> timeline(@PathVariable String id) {
        return ResponseEntity.ok(customerService.getTimeline(id));
    }

    @PostMapping("/{id}/notes")
    public ResponseEntity<Customer> addNote(@PathVariable String id, @Valid @RequestBody NoteRequest request) {
        String operatorId = SecurityContextHolder.getContext().getAuthentication().getPrincipal().toString();
        return ResponseEntity.ok(customerService.addNote(id, request, operatorId));
    }
}
