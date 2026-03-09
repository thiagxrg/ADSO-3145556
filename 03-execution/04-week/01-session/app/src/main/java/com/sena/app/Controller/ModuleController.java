package com.sena.app.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.sena.app.Entity.Module;
import com.sena.app.Service.ModuleService;

@RestController
@RequestMapping("/api/module")
public class ModuleController {
    
    private final ModuleService service;

    public ModuleController(ModuleService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<Module> create(@RequestBody Module module) {
        Module savedModule = service.save(module);
        return new ResponseEntity<>(savedModule, HttpStatus.CREATED);
    }

    @GetMapping
    public ResponseEntity<List<Module>> All() {       
        List<Module> people = service.All();
        return new ResponseEntity<>(people, HttpStatus.OK);
    }
}