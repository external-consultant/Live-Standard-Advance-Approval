codeunit 80930 "Approval Mgmt Subscribers"
{
    Permissions = tabledata "Approval Entry" = RDMI;
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", OnApproveApprovalRequest, '', false, false)]
    local procedure "Approvals Mgmt._OnApproveApprovalRequest"(var ApprovalEntry: Record "Approval Entry")
    begin
        if not (ApprovalEntry."Approval Type" = ApprovalEntry."Approval Type"::"Workflow User Group") then exit;

        //If ApprovalEntry."Sender ID" = ApprovalEntry."Approver ID" then exit;

        Cancelapprovalrequestforrecord(ApprovalEntry);
    end;

    procedure Cancelapprovalrequestforrecord(Var FromapprovalEntry: Record "Approval Entry")
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntryToUpdate: Record "Approval Entry";
        ApprovalMgmt: Codeunit "Approvals Mgmt.";
    begin
        ApprovalEntry.Reset();
        ApprovalEntry.SetCurrentKey("Table ID", "Document Type", "Document No.", "Sequence No.");
        ApprovalEntry.SetRange("Table ID", FromApprovalEntry."Table ID");
        ApprovalEntry.SetRange("Record ID to Approve", FromApprovalEntry."Record ID to Approve");
        ApprovalEntry.SetRange("Sequence No.", FromApprovalEntry."Sequence No.");
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.SetRange("Workflow Step Instance ID", FromApprovalEntry."Workflow Step Instance ID");
        if ApprovalEntry.FindSet() then
            repeat
                ApprovalEntryToUpdate := ApprovalEntry;
                ApprovalEntryToUpdate.Validate(Status, ApprovalEntryToUpdate.Status::Canceled);
                ApprovalEntryToUpdate.Modify(true);
            //ApprovalMgmt.CreateApprovalEntryNotification (ApprovalEntryToUpdate, WorkflowStepInstance);
            until ApprovalEntry.Next = 0;
    end;
}