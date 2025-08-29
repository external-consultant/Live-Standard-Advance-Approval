Codeunit 80932 Subscribe_Codeunit_415
{

    trigger OnRun()
    begin
    end;

    var
        Rec: Record "Purchase Header";
        CompanyInfo_gRec: Record "Company Information";
        Text001: label 'There is nothing to release for the document of type %1 with the number %2.';
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
        WhsePurchRelease: Codeunit "Whse.-Purch. Release";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnReleaseDocument', '', false, false)]
    local procedure OnReleaseDocument(RecRef: RecordRef; var Handled: Boolean);
    begin
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnBeforeReleaseDocument', '', false, false)]
    local procedure OnBeforeReleaseDocument(var Variant: Variant);
    begin
        ReleaseDocument(Variant);
    end;

    procedure ReleaseDocument(var Variant: Variant)
    var
        ApprovalEntry: Record "Approval Entry";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        ReleaseTransferDocument: Codeunit "Release Transfer Document";
        ReleaseServiceDocument: Codeunit "Release Service Document";
        ReleaseIncomingDocument: Codeunit "Release Incoming Document";
        RecRef: RecordRef;
        TargetRecRef: RecordRef;

        Handled: Boolean;
        //  ApprovalSetup: Record "Approval Setup";
        ApprovalMgtNotification: Codeunit "Approvals Mgt Notification";

    begin
        RecRef.GetTable(Variant);

        if RecRef.Number IN [DATABASE::"Approval Entry", DATABASE::"Purchase Header", DATABASE::"Sales Header", Database::"Transfer Header", Database::"Service Header", Database::"Production Order"] then begin
            case RecRef.Number of
                DATABASE::"Approval Entry":
                    begin
                        ApprovalEntry := Variant;
                        ApprovalEntry_gRec := Variant;
                        TargetRecRef.Get(ApprovalEntry."Record ID to Approve");
                        Variant := TargetRecRef;
                        ReleaseDocument(Variant);
                    end;
                DATABASE::"Purchase Header":
                    begin
                        ReleasePurchaseDocument.PerformManualCheckAndRelease(Variant);
                        COMMIT;
                        ApprovalMgtNotification.SendPurchaseApprovedMail_gFnc(Variant, ApprovalEntry_gRec);
                    end;

                DATABASE::"Sales Header":
                    begin
                        ReleaseSalesDocument.PerformManualCheckAndRelease(Variant);
                        COMMIT;
                        ApprovalMgtNotification.SendSalesApprovedMail_gFnc(Variant, ApprovalEntry_gRec);
                    end;
                Database::"Transfer Header":
                    begin
                        ApprovalMgtNotification.SendTransferApprovedMail_gFnc(Variant, ApprovalEntry_gRec);
                    end;
                Database::"Service Header":
                    begin
                        ApprovalMgtNotification.SendServiceApprovedMail_gFnc(Variant, ApprovalEntry_gRec);
                    end;
                Database::"Production Order":
                    begin
                        ApprovalMgtNotification.SendProductionApprovedMail_gFnc(Variant, ApprovalEntry_gRec);
                    end;

            end;
        end;
        CLEAR(ApprovalEntry_gRec);

    end;

    procedure PerformManualRelease(var IncomingDocument: Record "Incoming Document")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if ApprovalsMgmt.IsIncomingDocApprovalsWorkflowEnabled(IncomingDocument) and
           (IncomingDocument.Status = IncomingDocument.Status::New)
        then
            Error(DocReleasedWhenApprovedErr);

        CODEUNIT.Run(CODEUNIT::"Release Incoming Document", IncomingDocument);
    end;

    var
        DocReleasedWhenApprovedErr: Label 'This document can only be released when the approval process is complete.';
        UnsupportedRecordTypeErr: Label 'Record type %1 is not supported by this workflow response.', Comment = 'Record type Customer is not supported by this workflow response.';
        ApprovalEntry_gRec: record "Approval Entry";
        EmailBody_lTxt: Text;
    //Vendor_lRec: Record Vendor;


}

