package com.sena.app.IRepository;

import com.sena.app.Entity.Action;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface IActionRepository extends JpaRepository<Action, Long> {
}
