package com.wtc.chatapp.repository;

import com.wtc.chatapp.model.Customer;
import com.wtc.chatapp.model.CustomerStatus;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;
import java.util.Optional;

public interface CustomerRepository extends MongoRepository<Customer, String> {
    Optional<Customer> findByUserId(String userId);
    List<Customer> findByTagsContaining(String tag);
    List<Customer> findByStatus(CustomerStatus status);
    List<Customer> findByScoreGreaterThanEqual(int score);
}
