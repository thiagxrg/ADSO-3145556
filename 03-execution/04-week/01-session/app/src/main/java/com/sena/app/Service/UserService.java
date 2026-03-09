package com.sena.app.Service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.sena.app.Entity.User;
import com.sena.app.IRepository.IUserRepository;

@Service
public class UserService {
    @Autowired
    private IUserRepository repository;

    public User save(User user) {
        return repository.save(user );
    }

    public List<User> All() {
        return repository.findAll();
    }

}