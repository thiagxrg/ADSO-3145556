package com.sena.app.Entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "action")
public class Action extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "actions", nullable = false, length = 100)
    private String actions;

    @Column(name = "affected_table", length = 100)
    private String affectedTable;

    @Column(name = "date")
    private LocalDateTime date;

    @Column(name = "description", length = 255)
    private String description;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getActions() {
        return actions;
    }

    public void setActions(String actions) {
        this.actions = actions;
    }

    public String getAffectedTable() {
        return affectedTable;
    }

    public void setAffectedTable(String affectedTable) {
        this.affectedTable = affectedTable;
    }

    public LocalDateTime getDate() {
        return date;
    }

    public void setDate(LocalDateTime date) {
        this.date = date;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }
}