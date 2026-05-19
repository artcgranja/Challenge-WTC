package com.wtc.chatapp.service;

import com.wtc.chatapp.dto.CustomerRequest;
import com.wtc.chatapp.dto.NoteRequest;
import com.wtc.chatapp.model.Customer;
import com.wtc.chatapp.model.CustomerStatus;
import com.wtc.chatapp.model.Note;
import com.wtc.chatapp.repository.CustomerRepository;
import com.wtc.chatapp.repository.MessageRepository;
import com.wtc.chatapp.repository.UserRepository;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class CustomerService {

    private final CustomerRepository customerRepository;
    private final MessageRepository messageRepository;
    private final UserRepository userRepository;

    public CustomerService(CustomerRepository customerRepository, MessageRepository messageRepository, UserRepository userRepository) {
        this.customerRepository = customerRepository;
        this.messageRepository = messageRepository;
        this.userRepository = userRepository;
    }

    private Map<String, Object> enrichCustomer(Customer customer) {
        Map<String, Object> enriched = new HashMap<>();
        enriched.put("id", customer.getId());
        enriched.put("user_id", customer.getUserId());
        enriched.put("tags", customer.getTags());
        enriched.put("score", customer.getScore());
        enriched.put("status", customer.getStatus());
        enriched.put("notes", customer.getNotes());
        enriched.put("segment_ids", customer.getSegmentIds());
        enriched.put("created_at", customer.getCreatedAt());

        if (customer.getUserId() != null) {
            userRepository.findById(customer.getUserId()).ifPresent(user -> {
                enriched.put("full_name", user.getFullName());
                enriched.put("email", user.getEmail());
                enriched.put("phone", user.getPhone());
                enriched.put("avatar_url", user.getAvatarUrl());
            });
        }
        return enriched;
    }

    public List<Map<String, Object>> list(String tag, String status, Integer minScore) {
        List<Customer> customers;
        if (tag != null) {
            customers = customerRepository.findByTagsContaining(tag);
        } else if (status != null) {
            customers = customerRepository.findByStatus(CustomerStatus.valueOf(status.toUpperCase()));
        } else if (minScore != null) {
            customers = customerRepository.findByScoreGreaterThanEqual(minScore);
        } else {
            customers = customerRepository.findAll();
        }
        return customers.stream().map(this::enrichCustomer).toList();
    }

    public Customer getById(String id) {
        return customerRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found"));
    }

    public Customer create(CustomerRequest request) {
        Customer customer = Customer.builder()
                .userId(request.getUserId())
                .tags(request.getTags() != null ? request.getTags() : List.of())
                .score(request.getScore() != null ? request.getScore() : 0)
                .status(request.getStatus() != null ? CustomerStatus.valueOf(request.getStatus().toUpperCase()) : CustomerStatus.ACTIVE)
                .build();
        return customerRepository.save(customer);
    }

    public Customer update(String id, CustomerRequest request) {
        Customer customer = getById(id);
        if (request.getTags() != null) customer.setTags(request.getTags());
        if (request.getScore() != null) customer.setScore(request.getScore());
        if (request.getStatus() != null) customer.setStatus(CustomerStatus.valueOf(request.getStatus().toUpperCase()));
        customer.setUpdatedAt(Instant.now());
        return customerRepository.save(customer);
    }

    public Map<String, Object> getTimeline(String id) {
        Customer customer = getById(id);
        Map<String, Object> timeline = new HashMap<>();
        timeline.put("customer", enrichCustomer(customer));

        if (customer.getUserId() != null) {
            List<String> tags = customer.getTags();
            var messages = messageRepository.findInbox(customer.getUserId(),
                    tags != null ? tags : List.of(),
                    Sort.by(Sort.Direction.DESC, "createdAt"));
            timeline.put("messages", messages);
        }

        timeline.put("notes", customer.getNotes());
        return timeline;
    }

    public Customer addNote(String id, NoteRequest request, String operatorId) {
        Customer customer = getById(id);
        Note note = Note.builder()
                .text(request.getText())
                .createdBy(operatorId)
                .build();
        customer.getNotes().add(note);
        customer.setUpdatedAt(Instant.now());
        return customerRepository.save(customer);
    }
}
