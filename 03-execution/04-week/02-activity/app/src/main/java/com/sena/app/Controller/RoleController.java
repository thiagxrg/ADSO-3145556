package com.sena.app.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.sena.app.Entity.Role;
import com.sena.app.Service.RoleService;

@RestController
@RequestMapping("/api/role")
public class RoleController {
    
    private final RoleService service;

    public RoleController(RoleService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<Role> create(@RequestBody Role role) {
        Role savedRole = service.save(role);
        return new ResponseEntity<>(savedRole, HttpStatus.CREATED);
    }

    @GetMapping
    public ResponseEntity<List<Role>> All() {       
        List<Role> roles = service.All();
        return new ResponseEntity<>(roles, HttpStatus.OK);
    }
}