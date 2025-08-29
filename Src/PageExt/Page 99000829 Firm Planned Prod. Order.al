pageextension 80934 PgeExt_80934 extends "Firm Planned Prod. Order"
{

    PromotedActionCategories = 'New,Process,Report,Posting,Release,Order,Documents,Print/Send,Navigate,Approval';


    layout
    {
        addafter("Last Date Modified")
        {
            field("Order Status"; Rec."Order Status")
            {
                ApplicationArea = All;
            }
        }

    }

    actions
    {

        modify("Re&fresh Production Order")
        {
            Enabled = ActionButtonVisible_gBln;
        }
        modify("Re&plan")
        {
            Enabled = ActionButtonVisible_gBln;
        }
        modify("Change &Status")
        {
            Enabled = ActionButtonVisible_gBln;
        }
        addlast("O&rder")
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
                        If ProductionOrderWorkflowMgmt.CheckProductionOrderApprovalWorkFlowEnable(Rec) then
                            ProductionOrderWorkflowMgmt.OnSendProductionOrderForApproval(Rec);
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
                    var

                    begin
                        ProductionOrderWorkflowMgmt.OnCancleProductionOrderForApproval(Rec);
                    end;
                }
                action("Reopen Order Status")
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
                        if Rec."Order Status" = Rec."Order Status"::Open then
                            exit;

                        //OnBeforeReopenTransferDoc(ServHeader);
                        if Rec."Order Status" <> Rec."Order Status"::Released then
                            Error('Document must be released to Reopen it');

                        Rec.Validate("Order Status", Rec."Order Status"::Open);
                        Rec.Modify(true);
                        //YT on workflow Enable you want to reopen in manual-(Send for Approval Button )Button need to enable
                        ApprovalEntry_gRec.reset;
                        ApprovalEntry_gRec.SetRange("Record ID to Approve", rec.RecordId);
                        ApprovalEntry_gRec.SetRange(Status, ApprovalEntry_gRec.Status::Open);
                        if ApprovalEntry_gRec.FindSet() then
                            ProductionOrderWorkflowMgmt.RejectedApprovalEntry(ApprovalEntry_gRec);
                        //
                    end;
                }
                action("Release Order Status")
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
                    begin
                        if Rec."Order Status" = Rec."Order Status"::Released then
                            exit;

                        if ProductionOrderWorkflowMgmt.IsProductionOrderApprovalWorkFlowEnable(Rec) then
                            Error('Kindly , use Send for Approval action for Sending approval.')
                        else begin
                            Rec."Order Status" := Rec."Order Status"::Released;
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
                    // RunObject = Page "Approval Entries";
                    // RunPageLink = "Document No." = field("No.");
                    trigger OnAction()
                    var
                    begin
                        OpenApprovalsProduction(Rec);
                    end;
                }

                // action(Approve)                
                // {
                //     Enabled = OpenApprovalEntriesExistforCurruser_gBln;
                //     Image = Approve;
                //     Promoted = true;
                //     PromotedIsBig = true;
                //     PromotedCategory = Category10;
                //     PromotedOnly = true;
                //     ApplicationArea = All;

                //     trigger OnAction()
                //     var
                //     begin
                //         ApprovalsMgmt_gCdu.ApproveRecordApprovalRequest(Rec.RecordId);
                //     end;
                // }


                // action(Reject)
                // {
                //     Enabled = OpenApprovalEntriesExistforCurruser_gBln;
                //     Image = Reject;
                //     Promoted = true;
                //     PromotedIsBig = true;
                //     PromotedCategory = Category10;
                //     PromotedOnly = true;
                //     ApplicationArea = All;
                //     trigger OnAction()
                //     var
                //     begin
                //         ApprovalsMgmt_gCdu.RejectRecordApprovalRequest(Rec.RecordId);
                //     end;
                // }
            }
        }
    }
    trigger OnAfterGetCurrRecord()
    begin
        OpenApprovalEntriesExistforCurruser_gBln := ApprovalsMgmt_gCdu.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);

        OpenApprovalEntriesExist_gBln := ApprovalsMgmt_gCdu.HasOpenApprovalEntries(Rec.RecordId);
        CanCancelApprovalForRecord_gBln := ApprovalsMgmt_gCdu.CanCancelApprovalForRecord(Rec.RecordId);
        WorkflowWebhookMgt_gCdu.GetCanRequestAndCanCancel(Rec.RecordId, CanRequestApprovalForFlow_gBln, CanCancelApprovalForFlow_gBln);
        Activate_lFnc;
    end;

    trigger OnOpenPage()
    var
        myInt: Integer;
    begin
        Activate_lFnc;

    end;

    Local procedure Activate_lFnc()
    begin
        if rec."Order Status" in [rec."Order Status"::"Pending Approval", rec."Order Status"::Open] then
            ActionButtonVisible_gBln := false
        else
            ActionButtonVisible_gBln := true;

        if rec."Order Status" in [rec."Order Status"::"Pending Approval", rec."Order Status"::Released] then
            EditibleProBomVersion_gBln := false
        else
            EditibleProBomVersion_gBln := true;

        // if not ActionButtonVisible_gBln then
        //     CurrPage.Editable := false;

    end;

    local procedure OpenApprovalsProduction(ProductionOrder: Record "Production Order")
    begin
        RunWorkflowEntriesPage(
            ProductionOrder.RecordId(), DATABASE::"Production Order", Enum::"Approval Document Type"::Order, ProductionOrder."No.");
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

    var
        myInt: Integer;
        WorkflowWebhookMgt_gCdu: Codeunit "Workflow Webhook Management";
        ApprovalsMgmt_gCdu: Codeunit "Approvals Mgmt.";
        OpenApprovalEntriesExistforCurruser_gBln: Boolean;
        OpenApprovalEntriesExist_gBln: Boolean;
        CanCancelApprovalForRecord_gBln: Boolean;
        CanCancelApprovalForFlow_gBln: Boolean;
        CanRequestApprovalForFlow_gBln: Boolean;
        ActionButtonVisible_gBln: Boolean;
        ProductionOrderWorkflowMgmt: Codeunit "Production Order Workflow Mgmt";
        EditibleProBomVersion_gBln: Boolean;
        ApprovalEntry_gRec: Record "Approval Entry";

}