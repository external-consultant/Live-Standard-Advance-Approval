pageextension 80931 PageExt5740 extends "Transfer Order"
{
    PromotedActionCategories = 'New,Process,Report,Posting,Release,Order,Documents,Print/Send,Navigate,Approval';
    layout
    {

        addafter(Status)
        {
            field("Approval Status"; Rec."Approval Status 2")
            {
                ApplicationArea = All;
            }
            field("First Approval Completed"; Rec."First Approval Completed")
            {
                ApplicationArea = All;
                Visible = false;
                ToolTip = 'Specifies the value of the First Approval Completed field.', Comment = '%';
            }
        }
        //T12141-NB-NS
        modify(Status)
        {
            Visible = false;
        }
        //T12141-NB-NE
    }

    actions
    {
        addlast(Warehouse)
        {
            group("Request Approval")
            {
                action("Send A&pproval request")
                {
                    Enabled = Not OpenApprovalEntriesExist_gBln ANd CanRequestApprovalForFlow_gBln;
                    Image = SendApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedOnly = true;
                    ApplicationArea = ALL;
                    trigger OnAction()
                    begin
                        If TransferOrderWorkflowMgmt.CheckTransferHeaderApprovalWorkFlowEnable(Rec) then
                            TransferOrderWorkflowMgmt.OnSendTransferHeaderForApproval(Rec);
                    end;
                }
                action("Cancel Approval request")
                {
                    Enabled = CanCancelApprovalForRecord_gBln or CanCancelApprovalForFlow_gBln;
                    Image = CancelApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedOnly = true;
                    ApplicationArea = ALL;
                    trigger OnAction()
                    begin
                        TransferOrderWorkflowMgmt.OnCancleTransferHeaderForApproval(Rec);
                    end;
                }
                action("Reopen Approval Status 2")
                {
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedOnly = true;
                    ApplicationArea = ALL;
                    Caption = 'Re&open Approval';
                    Image = ReOpen;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have the Released status and must be opened before they can be changed.';

                    trigger OnAction()
                    var
                        ReleaseSalesDoc: Codeunit "Release Sales Document";
                    begin
                        if Rec."Approval Status 2" = Rec."Approval Status 2"::Open then
                            exit;

                        //OnBeforeReopenTransferDoc(ServHeader);
                        if Rec."Approval Status 2" <> Rec."Approval Status 2"::Released then
                            Error('Document must be released to Reopen it');

                        Rec.Validate("Approval Status 2", Rec."Approval Status 2"::Open);
                        Rec.Modify(true);

                    end;
                }
                action("Release Approval Status 2")
                {
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedOnly = true;
                    ApplicationArea = ALL;
                    Caption = 'Re&lease Approval';
                    Image = ReleaseDoc;
                    ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    var
                        "Transfer Order Workflow Mgmt": Codeunit "Transfer Order Workflow Mgmt";
                    begin
                        if Rec."Approval Status 2" = Rec."Approval Status 2"::Released then
                            exit;

                        If TransferOrderWorkflowMgmt.IsTransferHeaderApprovalWorkFlowEnable(Rec) then
                            Error('Kindly , use Send for Approval action for Sending approval.')
                        else begin
                            "Transfer Order Workflow Mgmt".RunFieldMadatoryCheckTransfer(Rec);
                            Rec."Approval Status 2" := Rec."Approval Status 2"::Released;
                            Codeunit.Run(Codeunit::"Release Transfer Document", Rec);
                            rec.Modify();
                        end;
                    end;
                }

                action(Approvals)
                {
                    AccessByPermission = TableData "Approval Entry" = R;
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedOnly = true;
                    ApplicationArea = ALL;
                    Caption = 'Approvals';
                    Image = Approvals;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                    begin
                        OpenApprovalsTransfer(Rec);
                    end;
                }

                action(Approve)
                {
                    Enabled = OpenApprovalEntriesExistforCurruser_gBln;
                    Image = Approve;
                    Promoted = true;
                    PromotedIsBig = true;
                    PromotedCategory = Category10;
                    PromotedOnly = true;
                    ApplicationArea = All;
                    trigger OnAction()
                    var
                    begin
                        ApprovalsMgmt_gCdu.ApproveRecordApprovalRequest(Rec.RecordId);
                    end;
                }


                action(Reject)
                {
                    Enabled = OpenApprovalEntriesExistforCurruser_gBln;
                    Image = Reject;
                    Promoted = true;
                    PromotedIsBig = true;
                    PromotedCategory = Category10;
                    PromotedOnly = true;
                    ApplicationArea = All;
                    trigger OnAction()
                    var
                    begin
                        ApprovalsMgmt_gCdu.RejectRecordApprovalRequest(Rec.RecordId);
                    end;
                }
            }
        }
    }

    local procedure OpenApprovalsTransfer(TransferHeader: Record "Transfer Header")
    begin
        RunWorkflowEntriesPage(
            TransferHeader.RecordId(), DATABASE::"Transfer Header", Enum::"Approval Document Type"::Order, TransferHeader."No.");
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
        TransferOrderWorkflowMgmt: Codeunit "Transfer Order Workflow Mgmt";
        WorkflowWebhookMgt_gCdu: Codeunit "Workflow Webhook Management";
        ApprovalsMgmt_gCdu: Codeunit "Approvals Mgmt.";
        OpenApprovalEntriesExistforCurruser_gBln: Boolean;
        OpenApprovalEntriesExist_gBln: Boolean;
        CanCancelApprovalForRecord_gBln: Boolean;
        CanCancelApprovalForFlow_gBln: Boolean;
        CanRequestApprovalForFlow_gBln: Boolean;
}