pageextension 80933 PageExt9318 extends "Service Orders"
{
    layout
    {
        addafter("Payment Method Code")
        {
            field("Approval Status"; Rec."Approval Status 2")
            {
                ApplicationArea = All;
            }
        }
    }



    actions
    {
        addlast(processing)
        {
            group("Request Approval")
            {
                action("Send A&pproval request")
                {
                    Enabled = Not OpenApprovalEntriesExist_gBln ANd CanRequestApprovalForFlow_gBln;
                    Image = SendApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ApplicationArea = ALL;
                    trigger OnAction()
                    begin
                        If ServiceOrderWorkflowMgmt.CheckServiceHeaderApprovalWorkFlowEnable(Rec) then
                            ServiceOrderWorkflowMgmt.OnSendServiceHeaderForApproval(Rec);
                    end;
                }
                action("Cancel Approval request")
                {
                    Enabled = CanCancelApprovalForRecord_gBln or CanCancelApprovalForFlow_gBln;
                    Image = CancelApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ApplicationArea = ALL;
                    trigger OnAction()
                    begin
                        ServiceOrderWorkflowMgmt.OnCancleServiceHeaderForApproval(Rec);
                    end;
                }


                action(Approvals)
                {
                    AccessByPermission = TableData "Approval Entry" = R;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ApplicationArea = ALL;
                    Caption = 'Approvals';
                    Image = Approvals;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                    begin
                        OpenApprovalsService(Rec);
                    end;
                }
            }
        }
    }

    local procedure OpenApprovalsService(ServiceHeader: Record "Service Header")
    begin
        RunWorkflowEntriesPage(
            ServiceHeader.RecordId(), DATABASE::"Service Header", ServiceHeader."Document Type", ServiceHeader."No.");
    end;

    Local procedure RunWorkflowEntriesPage(RecordIDInput: RecordID; TableId: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20])
    var
        ApprovalEntry: Record "Approval Entry";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        Approvals: Page Approvals;
        WorkflowWebhookEntries: Page "Workflow Webhook Entries";
        ApprovalEntries: Page "Approval Entries";
    begin

        // if we are looking at a particular record, we want to see only record related workflow entries
        if DocumentNo <> '' then begin
            ApprovalEntry.SetRange("Record ID to Approve", RecordIDInput);
            WorkflowWebhookEntry.SetRange("Record ID", RecordIDInput);
            // if we have flows created by multiple applications, start generic page filtered for this RecordID
            if not ApprovalEntry.IsEmpty() and not WorkflowWebhookEntry.IsEmpty() then begin
                Approvals.Setfilters(RecordIDInput);
                Approvals.Run();
            end else begin
                // otherwise, open the page filtered for this record that corresponds to the type of the flow
                if not WorkflowWebhookEntry.IsEmpty() then begin
                    WorkflowWebhookEntries.Setfilters(RecordIDInput);
                    WorkflowWebhookEntries.Run();
                    exit;
                end;

                if not ApprovalEntry.IsEmpty() then begin
                    ApprovalEntries.SetRecordFilters(TableId, DocumentType, DocumentNo);
                    ApprovalEntries.Run();
                    exit;
                end;

                // if no workflow exist, show (empty) joint workflows page
                Approvals.Setfilters(RecordIDInput);
                Approvals.Run();
            end
        end else
            // otherwise, open the page with all workflow entries
            Approvals.Run();
    end;



    trigger OnAfterGetRecord()
    begin
        OpenApprovalEntriesExistforCurruser_gBln := ApprovalsMgmt_gCdu.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);
        OpenApprovalEntriesExist_gBln := ApprovalsMgmt_gCdu.HasOpenApprovalEntries(Rec.RecordId);
        CanCancelApprovalForRecord_gBln := ApprovalsMgmt_gCdu.CanCancelApprovalForRecord(Rec.RecordId);
        WorkflowWebhookMgt_gCdu.GetCanRequestAndCanCancel(Rec.RecordId, CanRequestApprovalForFlow_gBln, CanCancelApprovalForFlow_gBln);
    end;



    var
        ServiceOrderWorkflowMgmt: Codeunit "Service Order Workflow Mgmt";
        WorkflowWebhookMgt_gCdu: Codeunit "Workflow Webhook Management";
        ApprovalsMgmt_gCdu: Codeunit "Approvals Mgmt.";
        OpenApprovalEntriesExistforCurruser_gBln: Boolean;
        OpenApprovalEntriesExist_gBln: Boolean;
        CanCancelApprovalForRecord_gBln: Boolean;
        CanCancelApprovalForFlow_gBln: Boolean;
        CanRequestApprovalForFlow_gBln: Boolean;
}