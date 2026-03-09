package com.sena.app.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.sena.app.Entity.View;
import com.sena.app.Service.ViewService;

@RestController
@RequestMapping("/api/view")
public class ViewController {
    
    private final ViewService service;

    public ViewController(ViewService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<View> create(@RequestBody View VIEW) {
        View savedView = service.save(VIEW);
        return new ResponseEntity<>(savedView, HttpStatus.CREATED);
    }

    @GetMapping
    public ResponseEntity<List<View>> All() {       
        List<View> people = service.All();
        return new ResponseEntity<>(people, HttpStatus.OK);
    }
}