package com.wtc.chatapp.repository;

import com.wtc.chatapp.model.Campaign;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface CampaignRepository extends MongoRepository<Campaign, String> {
    List<Campaign> findAllByOrderByCreatedAtDesc();
}
