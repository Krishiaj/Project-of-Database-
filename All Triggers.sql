

1st Trigger

CREATE OR REPLACE TRIGGER trg_update_membership_status
BEFORE UPDATE OR INSERT ON Member
FOR EACH ROW
BEGIN
  -- Check if it's an update and the EndDate is being changed to a past date
  IF UPDATING AND :NEW.EndDate < SYSDATE AND :OLD.EndDate != :NEW.EndDate THEN
    :NEW.MembershipType := 'Inactive';
  ELSIF INSERTING AND :NEW.EndDate < SYSDATE THEN
     :NEW.MembershipType := 'Inactive';
  --Check if it is an insert and the end date is in the future
    ELSIF INSERTING AND :NEW.EndDate >= SYSDATE THEN
      :NEW.MembershipType := 'Active';
  END IF;
END;
/

2nd Trigger


CREATE OR REPLACE TRIGGER trg_update_class_capacity
BEFORE INSERT ON Member -- Assuming this is the junction table for Member and Class
FOR EACH ROW
DECLARE
    v_current_capacity NUMBER;
    v_max_capacity NUMBER;
BEGIN
    -- Get the current capacity and max capacity of the class
    SELECT COUNT(*), (SELECT Capacity FROM Class WHERE ClassID = :NEW.ClassID)
    INTO v_current_capacity, v_max_capacity
    FROM Member_Class
    WHERE ClassID = :NEW.ClassID;

    -- Check if adding another member exceeds the capacity
    IF v_current_capacity >= v_max_capacity THEN
        RAISE_APPLICATION_ERROR(-20001, 'Class is full. Cannot book.');
    END IF;

    -- If capacity is not exceeded, you could optionally update a separate "spots_available" column
    -- in the Class table (if you have one). This is redundant if you calculate spots dynamically.
    -- Example (if you have a SpotsAvailable column):
    -- UPDATE Class SET SpotsAvailable = v_max_capacity - (v_current_capacity + 1) WHERE ClassID = :NEW.ClassID;
END;
/

3rd Trigger 


CREATE OR REPLACE TRIGGER trg_notify_membership_expiry
BEFORE UPDATE ON Member
FOR EACH ROW
DECLARE
    v_days_remaining NUMBER;
BEGIN
    -- Calculate days remaining until expiry
    v_days_remaining := :NEW.EndDate - SYSDATE;

    -- Check if expiry is within 7 days and membership is active
    IF v_days_remaining <= 7 AND v_days_remaining >= 0 AND :NEW.MembershipType = 'Active' THEN
    

    DBMS_OUTPUT.PUT_LINE('Membership expiring soon... Expires in ' || TRUNC(:NEW.EndDate - SYSDATE) || ' days.');

    END IF;
End;
/


