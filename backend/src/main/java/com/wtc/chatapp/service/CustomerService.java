package com.wtc.chatapp.service;

import com.wtc.chatapp.dto.CustomerRequest;
import com.wtc.chatapp.dto.NoteRequest;
import com.wtc.chatapp.model.Customer;
import com.wtc.chatapp.model.CustomerStatus;
import com.wtc.chatapp.model.Note;
import com.wtc.chatapp.repository.CustomerRepository;
import com.wtc.chatapp.repository.MessageRepository;
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

    public CustomerService(CustomerRepository customerRepository, MessageRepository messageRepository) {
        this.customerRepository = customerRepository;
        this.messageRepository = messageRepository;
    }

    public List<Customer> list(String tag, String status, Integer minScore) {
        if (tag != null) {
            return customerRepository.findByTagsContaining(tag);
        }
        if (status != null) {
            return customerRepository.findByStatus(CustomerStatus.valueOf(status.toUpperCase()));
        }
        if (minScore != null) {
            return customerRepository.findByScoreGreaterThanEqual(minScore);
        }
        return customerRepository.findAll();
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
        timeline.put("customer", customer);

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
