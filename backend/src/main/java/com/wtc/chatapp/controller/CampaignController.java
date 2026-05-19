package com.wtc.chatapp.controller;

import com.wtc.chatapp.dto.CampaignRequest;
import com.wtc.chatapp.model.Campaign;
import com.wtc.chatapp.service.CampaignService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/campaigns")
public class CampaignController {

    private final CampaignService campaignService;

    public CampaignController(CampaignService campaignService) {
        this.campaignService = campaignService;
    }

    @GetMapping
    public ResponseEntity<List<Campaign>> list() {
        return ResponseEntity.ok(campaignService.list());
    }

    @PostMapping
    public ResponseEntity<Campaign> create(@Valid @RequestBody CampaignRequest request) {
        String operatorId = SecurityContextHolder.getContext().getAuthentication().getPrincipal().toString();
        return ResponseEntity.status(HttpStatus.CREATED).body(campaignService.create(request, operatorId));
    }

    @PostMapping("/{id}/send")
    public ResponseEntity<Campaign> send(@PathVariable String id) {
        String operatorId = SecurityContextHolder.getContext().getAuthentication().getPrincipal().toString();
        return ResponseEntity.ok(campaignService.send(id, operatorId));
    }
}
