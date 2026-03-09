package com.sena.app.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.sena.app.Entity.Action;
import com.sena.app.Service.ActionService;

@RestController
@RequestMapping("/api/action")
public class ActionController {
    
    private final ActionService service;

    public ActionController(ActionService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<Action> create(@RequestBody Action action) {
        Action savedAction = service.save(action);
        return new ResponseEntity<>(savedAction, HttpStatus.CREATED);
    }

    @GetMapping
    public ResponseEntity<List<Action>> All() {       
        List<Action> people = service.All();
        return new ResponseEntity<>(people, HttpStatus.OK);
    }
}