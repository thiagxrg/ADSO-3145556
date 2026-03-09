package com.sena.app.Service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.sena.app.Entity.View;
import com.sena.app.IRepository.IViewRepository;

@Service
public class ViewService {
    @Autowired
    private IViewRepository repository;

    public View save(View view) {
        return repository.save(view);
    }

    public List<View> All() {
        return repository.findAll();
    }

}
