package com.sena.app.IRepository;

import com.sena.app.Entity.View;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface IViewRepository extends JpaRepository<View, Long> {
}
