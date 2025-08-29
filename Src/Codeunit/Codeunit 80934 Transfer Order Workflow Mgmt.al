
codeunit 80934 "Transfer Order Workflow Mgmt"
{
    [IntegrationEvent(false, false)]
    procedure OnSendTransferHeaderForApproval(Var TransferHeader: Record "Transfer Header")
    var
    Begin
    End;

    [IntegrationEvent(false, false)]
    procedure OnCancleTransferHeaderForApproval(Var TransferHeader: Record "Transfer Header")
    var
    Begin
    End;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTransferApprovalPossible(var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    procedure CheckTransferHeaderApprovalWorkFlowEnable(Var TransferHeader: Record "Transfer Header"): Boolean
    var
        IsHandled: Boolean;
    Begin
        OnBeforeCheckTransferApprovalPossible(TransferHeader, IsHandled);
        if IsHandled then
            exit;

        If Not IsTransferHeaderApprovalWorkFlowEnable(TransferHeader) then
            Error(NoWorkFlowEnableErr_gTxt);
        exit(true);
    End;

    procedure IsTransferHeaderApprovalWorkFlowEnable(Var TransferHeader: Record "Transfer Header"): Boolean
    var
    Begin
        If TransferHeader."Approval Status 2" <> TransferHeader."Approval Status 2"::Open then
            exit(false);
        exit(WorkflowManagement_gCdu.CanExecuteWorkflow(TransferHeader, RunWorkflowOnSendTransferHeaderForApprovalCode()))
    End;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnPopulateApprovalEntryArgument', '', true, true)]
    local procedure OnPopulateApprovalEntryArgument(var RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry")
    Var
        TransferHeader_lRec: Record "Transfer Header";
    begin
        Case RecRef.Number of
            Database::"Transfer Header":
                begin
                    //Insert the data to approval entries
                    RecRef.SetTable(TransferHeader_lRec);
                    ApprovalEntryArgument."Document No." := TransferHeader_lRec."No.";
                    ApprovalEntryArgument."Document Type" := ApprovalEntryArgument."Document Type"::Order;
                end;
        End;
    end;





    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsTolibrary', '', true, true)]
    local procedure OnAddWorkflowEventsToLibrary()
    begin
        WorkflowEventHandling_gCdu.AddEventToLibrary(RunWorkflowOnSendTransferHeaderForApprovalCode, Database::"Transfer Header", TransferHeaderSendForApprovalEventDescTxt_gTxt, 0, false);
        WorkflowEventHandling_gCdu.AddEventToLibrary(RunWorkflowOnCancelTransferHeaderApprovalCode, Database::"Transfer Header", TransferHeaderApprovalRequestCancelEventDescTxt_gTxt, 0, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddworkflowEventPredecessorsToLibrary', '', true, true)]
    local procedure OnAddworkflowEventPredecessorsTolibrary(EventFunctionName: Code[128])
    begin
        case EventFunctionName of
            RunWorkflowonCancelTransferHeaderApprovalCode:
                WorkflowEventHandling_gCdu.AddEventPredecessor(RunWorkflowonCancelTransferHeaderApprovalCode, RunWorkflowOnSendTransferHeaderForApprovalCode);
            WorkflowEventHandling_gCdu.RunWorkflowOnApproveApprovalRequestCode:
                WorkflowEventHandling_gCdu.AddEventPredecessor(WorkflowEventHandling_gCdu.RunWorkflowOnApproveApprovalRequestCode, RunWorkflowOnSendTransferHeaderForApprovalCode);

        end;
    end;

    procedure RunWorkflowOnSendTransferHeaderForApprovalCode(): code[128]
    begin
        exit(UpperCase('RUNWORKFLOWONSENDTransferHEADERFORAPPROVAL'))
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Transfer Order Workflow Mgmt", 'OnSendTransferHeaderForApproval', '', true, true)]
    local procedure RunWorkflowOnSendTransferHeaderForApproval(Var TransferHeader: Record "Transfer Header")
    begin
        Workflowmanagement_gCdu.HandleEvent(RunWorkflowOnSendTransferHeaderForApprovalCode, TransferHeader);
    end;

    procedure RunWorkflowOnCancelTransferHeaderApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunkorkflowOnCancelTransferHeaderApproval'));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Transfer Order Workflow Mgmt", 'OnCancleTransferHeaderForApproval', '', true, true)]
    local procedure RunWorkflowOnCancelTransferHeaderApproval(Var TransferHeader: Record "Transfer Header")
    begin
        Workflowmanagement_gCdu.HandleEvent(RunWorkflowOnCancelTransferHeaderApprovalCode, TransferHeader);
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnOpenDocument', '', true, true)]
    local procedure OnOpenDocument(RecRef: RecordRef; Var Handled: Boolean)
    var
        TransferHeader_lRec: Record "Transfer Header";
    begin
        CASE RecRef.NUMBER OF
            DATABASE::"Transfer Header":
                begin
                    RecRef.SetTable(TransferHeader_lRec);
                    TransferHeader_lRec."Approval Status 2" := TransferHeader_lRec."Approval Status 2"::Open;
                    TransferHeader_lRec.Modify;
                    Handled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnReleaseDocument', '', true, true)]
    local procedure OnReleaseDocument(RecRef: RecordRef; Var Handled: Boolean)
    var
        TransferHeader_lRec: Record "Transfer Header";
    begin
        CASE RecRef.NUMBER OF
            DATABASE::"Transfer Header":
                begin
                    RecRef.SetTable(TransferHeader_lRec);
                    TransferHeader_lRec."Approval Status 2" := TransferHeader_lRec."Approval Status 2"::Released;
                    Codeunit.Run(Codeunit::"Release Transfer Document", TransferHeader_lRec);
                    If TransferHeader_lRec."First Approval Completed" = false then
                        TransferHeader_lRec."First Approval Completed" := true;
                    Clear(TransferHeader_lRec."Workflow Category Type");
                    TransferHeader_lRec.Modify;
                    Handled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSetStatusToPendingApproval', '', true, true)]
    local procedure OnSetStatusToPendingApproval(RecRef: RecordRef; Var Variant: Variant; Var IsHandled: Boolean)
    var
        TransferHeader_lRec: Record "Transfer Header";
    begin
        CASE RecRef.NUMBER OF
            DATABASE::"Transfer Header":
                begin
                    RecRef.SetTable(TransferHeader_lRec);
                    TransferHeader_lRec."Approval Status 2" := TransferHeader_lRec."Approval Status 2"::"Pending Approval";
                    TransferHeader_lRec.Modify;
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsePredecessorsToLibrary', '', true, true)]
    local procedure OnAddWorkflowResponsePredecessorsToLibrary(ResponseFunctionName: Code[128])
    var
        WorkflowResponseHandling_lCdu: Codeunit 1521;
    begin
        case ResponseFunctionName of
            WorkflowResponseHandling_lCdu.SetStatusToPendingApprovalCode:
                WorkflowResponseHandling_lCdu.AddResponsePredecessor(WorkflowResponseHandling_lCdu.SetStatusToPendingApprovalCode, RunWorkflowOnSendTransferHeaderForApprovalCode);
            WorkflowResponseHandling_lCdu.SendApprovalRequestForApprovalCode:
                WorkflowResponseHandling_lCdu.AddResponsePredecessor(WorkflowResponseHandling_lCdu.SendApprovalRequestForApprovalCode, RunWorkflowOnSendTransferHeaderForApprovalCode);
            WorkflowResponseHandling_lCdu.CancelAllApprovalRequestsCode:
                WorkflowResponseHandling_lCdu.AddResponsePredecessor(WorkflowResponseHandling_lCdu.CancelAllApprovalRequestsCode, RunWorkflowOnCancelTransferHeaderApprovalCode);
            WorkflowResponseHandling_lCdu.OpenDocumentCode:
                WorkflowResponseHandling_lCdu.AddResponsePredecessor(WorkflowResponseHandling_lCdu.OpenDocumentCode, RunWorkflowOnCancelTransferHeaderApprovalCode);
        End;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Transfer Order Workflow Mgmt", OnBeforeCheckTransferApprovalPossible, '', false, false)]
    local procedure "Approvals Mgmt._OnBeforeCheckTransferApprovalPossible"(var TransferHeader: Record "Transfer Header")
    begin
        RunFieldMadatoryCheckTransfer(TransferHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", OnBeforeOnRun, '', false, false)]
    local procedure "TransferOrder-Post Shipment_OnBeforeOnRun"(var TransferHeader: Record "Transfer Header"; var HideValidationDialog: Boolean; var SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
        RunFieldMadatoryCheckTransfer(TransferHeader);
    end;


    procedure RunFieldMadatoryCheckTransfer(var TransferHeader: Record "Transfer Header")
    var
        // FieldMandatorySetup_lRec: Record "Field Mandatory Setup";
        ConfTempHead_lRec: Record "Config. Template Header";
        ConfTempLine_lRec: Record "Config. Template Line";
        FieldRef_lFrf: FieldRef;
        RecRef_lRrf: RecordRef;
        ErrorMsghandler: Codeunit "Error Message Handler";
        ErrorMsgMgt: Codeunit "Error Message Management";
        Fieldvalue_txt: Text;
        FieldMandtempSetup_lRec: Record "Field Mand. Templ. Setup";
        ConditionFilter_lText: Text;
        TransferHeaderDocNoFilter_lText: Text;
        RecordRef_lSH: RecordRef;
        TemplateFound_lCode: Code[10];
        TemplateFound_lInt: Integer;
    begin
        // FieldMandatorySetup_lRec.Get();
        // FieldMandatorySetup_lRec.TestField("Trans. Head. Config. Template");

        TransferHeaderDocNoFilter_lText := ',Field1=1(' + TransferHeader."No." + '))';

        TemplateFound_lCode := '';
        FieldMandtempSetup_lRec.Reset();
        FieldMandtempSetup_lRec.SetRange("Record Type", FieldMandtempSetup_lRec."Record Type"::"Transfer Document");
        FieldMandtempSetup_lRec.SetRange(Enabled, true);
        FieldMandtempSetup_lRec.SetRange("Table Id", Database::"Transfer Header");
        If FieldMandtempSetup_lRec.FindSet() then
            repeat
                Clear(ConditionFilter_lText);
                ConditionFilter_lText := CopyStr(GetConditionAsDisplayText(FieldMandtempSetup_lRec), 1, StrLen(GetConditionAsDisplayText(FieldMandtempSetup_lRec)) - 1);
                ConditionFilter_lText := ConditionFilter_lText + TransferHeaderDocNoFilter_lText;
                if TemplateFound_lCode = '' then begin
                    RecordRef_lSH.Open(Database::"Transfer Header");
                    RecordRef_lSH.SetView(ConditionFilter_lText);
                    if RecordRef_lSH.FindFirst() then begin
                        TemplateFound_lCode := FieldMandtempSetup_lRec."Config. Template";
                        TemplateFound_lInt := FieldMandtempSetup_lRec.ID;
                    end;
                    RecordRef_lSH.Close();
                end;
            until FieldMandtempSetup_lRec.Next() = 0;

        // if TemplateFound_lCode = '' then
        //     Error('Configuration Template must have value in Field Mandatory Template Setup for ID: %1', TemplateFound_lInt);

        ErrorMsgMgt.Activate(ErrorMsghandler);
        ConfTempHead_lRec.Reset();
        ConfTempHead_lRec.SetRange(Code, TemplateFound_lCode);
        ConfTempHead_lRec.SetRange("Table ID", Database::"Transfer Header");
        if ConfTempHead_lRec.FindFirst() then begin
            ConfTempLine_lRec.Reset();
            ConfTempLine_lRec.SetRange("Data Template Code", ConfTempHead_lRec.Code);
            if ConfTempLine_lRec.FindSet() then
                repeat
                    RecRef_lRrf.GetTable(TransferHeader);
                    FieldRef_lFrf := RecRef_lRrf.Field(ConfTempLine_lRec."Field ID");
                    Fieldvalue_txt := Format(FieldRef_lFrf.Value);
                    if Fieldvalue_txt = '' then
                        ErrorMsgMgt.LogSimpleErrorMessage('Error In Process! ' + FieldRef_lFrf.Caption + ' must have value');
                until ConfTempLine_lRec.Next() = 0;
            if ErrorMsghandler.HasErrors() then
                if ErrorMsghandler.ShowErrors() then
                    Error('');
        end;
    end;

    procedure GetConditionAsDisplayText(FieldMandtempSetup_lRec: Record "Field Mand. Templ. Setup"): Text
    var
        Allobj: Record AllObj;
        RecordRef: RecordRef;
        IStream: InStream;
        COnditionText: Text;
        ExitMsg: Label 'Always';
        ObjectIDNotFoundErr: Label 'Error : Table ID %1 not found', Comment = '%1=Table Id';
    begin
        if not Allobj.Get(Allobj."Object Type"::Table, FieldMandtempSetup_lRec."Table Id") then
            exit(StrSubstNo(ObjectIDNotFoundErr, FieldMandtempSetup_lRec."Table Id"));
        RecordRef.Open(FieldMandtempSetup_lRec."Table ID");
        FieldMandtempSetup_lRec.CalcFields(Condition);
        if not FieldMandtempSetup_lRec.Condition.HasValue() then
            exit(ExitMsg);

        FieldMandtempSetup_lRec.Condition.CreateInStream(IStream);
        IStream.Read(COnditionText);
        exit(COnditionText);
    end;

    //T12141-NS
    //For Transfer Header Financial Fields

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterValidateEvent', 'Transaction Type', true, true)]
    local procedure TransferHeader_OnAfterValidateEvent_Transactiontype(var Rec: Record "Transfer Header"; var xRec: Record "Transfer Header"; CurrFieldNo: Integer)
    var
        CategoryType: Code[10];
    begin
        If Rec.IsTemporary then
            exit;

        if not Rec."First Approval Completed" then
            exit;

        if CurrFieldNo <> Rec.FieldNo("Transaction Type") then
            exit;

        CategoryType := UpdateWorkflow('Financial', Rec."Workflow Category Type");

        if Rec."Workflow Category Type" <> CategoryType then begin
            Rec."Workflow Category Type" := CategoryType;
            Rec.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterValidateEvent', 'Transfer-from Code', true, true)]
    local procedure TransferHeader_OnAfterValidateEvent_TransactionfromCode(var Rec: Record "Transfer Header"; var xRec: Record "Transfer Header"; CurrFieldNo: Integer)
    var
        CategoryType: Code[10];
    begin
        If Rec.IsTemporary then
            exit;

        if not Rec."First Approval Completed" then
            exit;

        if CurrFieldNo <> Rec.FieldNo("Transfer-from Code") then
            exit;

        CategoryType := UpdateWorkflow('Financial', Rec."Workflow Category Type");

        if Rec."Workflow Category Type" <> CategoryType then begin
            Rec."Workflow Category Type" := CategoryType;
            Rec.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterValidateEvent', 'Transfer-to Code', true, true)]
    local procedure TransferHeader_OnAfterValidateEvent_Transfertocode(var Rec: Record "Transfer Header"; var xRec: Record "Transfer Header"; CurrFieldNo: Integer)
    var
        CategoryType: Code[10];
    begin
        If Rec.IsTemporary then
            exit;

        if not Rec."First Approval Completed" then
            exit;

        if CurrFieldNo <> Rec.FieldNo("Transfer-to Code") then
            exit;

        CategoryType := UpdateWorkflow('Financial', Rec."Workflow Category Type");

        if Rec."Workflow Category Type" <> CategoryType then begin
            Rec."Workflow Category Type" := CategoryType;
            Rec.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterValidateEvent', 'In-Transit Code', true, true)]
    local procedure TransferHeader_OnAfterValidateEvent_InTransitCode(var Rec: Record "Transfer Header"; var xRec: Record "Transfer Header"; CurrFieldNo: Integer)
    var
        CategoryType: Code[10];
    begin
        If Rec.IsTemporary then
            exit;

        if not Rec."First Approval Completed" then
            exit;

        if CurrFieldNo <> Rec.FieldNo("In-Transit Code") then
            exit;

        CategoryType := UpdateWorkflow('Financial', Rec."Workflow Category Type");

        if Rec."Workflow Category Type" <> CategoryType then begin
            Rec."Workflow Category Type" := CategoryType;
            Rec.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterValidateEvent', 'Outbound Whse. Handling Time', true, true)]
    local procedure TransferHeader_OnAfterValidateEvent_OutBoundWhseHandlingtime(var Rec: Record "Transfer Header"; var xRec: Record "Transfer Header"; CurrFieldNo: Integer)
    var
        CategoryType: Code[10];
    begin
        If Rec.IsTemporary then
            exit;

        if not Rec."First Approval Completed" then
            exit;

        if CurrFieldNo <> Rec.FieldNo("Outbound Whse. Handling Time") then
            exit;

        CategoryType := UpdateWorkflow('Financial', Rec."Workflow Category Type");

        if Rec."Workflow Category Type" <> CategoryType then begin
            Rec."Workflow Category Type" := CategoryType;
            Rec.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterValidateEvent', 'Inbound Whse. Handling Time', true, true)]
    local procedure TransferHeader_OnAfterValidateEvent_InBoundWhseHandling(var Rec: Record "Transfer Header"; var xRec: Record "Transfer Header"; CurrFieldNo: Integer)
    var
        CategoryType: Code[10];
    begin
        If Rec.IsTemporary then
            exit;

        if not Rec."First Approval Completed" then
            exit;

        if CurrFieldNo <> Rec.FieldNo("Inbound Whse. Handling Time") then
            exit;

        CategoryType := UpdateWorkflow('Financial', Rec."Workflow Category Type");

        if Rec."Workflow Category Type" <> CategoryType then begin
            Rec."Workflow Category Type" := CategoryType;
            Rec.Modify();
        end;
    end;


    //For Transfer Header Non-Financial Fields
    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterValidateEvent', 'Vehicle No.', true, true)]
    local procedure TransferHeader_OnAfterValidateEvent_VehicleNo(var Rec: Record "Transfer Header"; var xRec: Record "Transfer Header"; CurrFieldNo: Integer)
    var
        CategoryType: Code[10];
    begin
        If Rec.IsTemporary then
            exit;

        if not Rec."First Approval Completed" then
            exit;

        if CurrFieldNo <> Rec.FieldNo("Vehicle No.") then
            exit;

        CategoryType := UpdateWorkflow('Non-Financial', Rec."Workflow Category Type");

        if Rec."Workflow Category Type" <> CategoryType then begin
            Rec."Workflow Category Type" := CategoryType;
            Rec.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterValidateEvent', 'Shipment Method Code', true, true)]
    local procedure TransferHeader_OnAfterValidateEvent_Shipmentmethodcode(var Rec: Record "Transfer Header"; var xRec: Record "Transfer Header"; CurrFieldNo: Integer)
    var
        CategoryType: Code[10];
    begin
        If Rec.IsTemporary then
            exit;

        if not Rec."First Approval Completed" then
            exit;

        if CurrFieldNo <> Rec.FieldNo("Shipment Method Code") then
            exit;

        CategoryType := UpdateWorkflow('Non-Financial', Rec."Workflow Category Type");

        if Rec."Workflow Category Type" <> CategoryType then begin
            Rec."Workflow Category Type" := CategoryType;
            Rec.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterValidateEvent', 'Shipment Date', true, true)]
    local procedure TransferHeader_OnAfterValidateEvent_ShipmentDate(var Rec: Record "Transfer Header"; var xRec: Record "Transfer Header"; CurrFieldNo: Integer)
    var
        CategoryType: Code[10];
    begin
        If Rec.IsTemporary then
            exit;

        if not Rec."First Approval Completed" then
            exit;

        if CurrFieldNo <> Rec.FieldNo("Shipment Date") then
            exit;

        CategoryType := UpdateWorkflow('Non-Financial', Rec."Workflow Category Type");

        if Rec."Workflow Category Type" <> CategoryType then begin
            Rec."Workflow Category Type" := CategoryType;
            Rec.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterValidateEvent', 'Receipt Date', true, true)]
    local procedure TransferHeader_OnAfterValidateEvent_ReceiptDate(var Rec: Record "Transfer Header"; var xRec: Record "Transfer Header"; CurrFieldNo: Integer)
    var
        CategoryType: Code[10];
    begin
        If Rec.IsTemporary then
            exit;

        if not Rec."First Approval Completed" then
            exit;

        if CurrFieldNo <> Rec.FieldNo("Receipt Date") then
            exit;

        CategoryType := UpdateWorkflow('Non-Financial', Rec."Workflow Category Type");

        if Rec."Workflow Category Type" <> CategoryType then begin
            Rec."Workflow Category Type" := CategoryType;
            Rec.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterValidateEvent', 'Vehicle Type', true, true)]
    local procedure TransferHeader_OnAfterValidateEvent_VehicleType(var Rec: Record "Transfer Header"; var xRec: Record "Transfer Header"; CurrFieldNo: Integer)
    var
        CategoryType: Code[10];
    begin
        If Rec.IsTemporary then
            exit;

        if not Rec."First Approval Completed" then
            exit;

        if CurrFieldNo <> Rec.FieldNo("Vehicle Type") then
            exit;

        CategoryType := UpdateWorkflow('Non-Financial', Rec."Workflow Category Type");

        if Rec."Workflow Category Type" <> CategoryType then begin
            Rec."Workflow Category Type" := CategoryType;
            Rec.Modify();
        end;
    end;

    local procedure UpdateWorkflow(StatusType: Text; FinStatus: Text): Text
    begin
        If (StatusType = 'Financial') and (FinStatus = '1') then
            exit;

        If (StatusType = 'Non-Financial') and (FinStatus = '2') then
            exit;


        if (FinStatus = '1|2') then
            exit(FinStatus);

        If StatusType = 'Financial' then begin
            If FinStatus = '' then
                exit('1');
            if FinStatus = '2' then
                exit('1|2');
        end;

        If StatusType = 'Non-Financial' then begin
            If FinStatus = '' then
                exit('2');
            if FinStatus = '1' then
                exit('1|2');
        end;

    end;
    //T12141-NE
    var
        WorkflowManagement_gCdu: Codeunit "Workflow Management";
        NoWorkFlowEnableErr_gTxt: TextConst ENU = 'No approval workflow for this record type is enable.';

        WorkflowEventHandling_gCdu: Codeunit 1520;
        TransferHeaderSendForApprovalEventDescTxt_gTxt: TextConst ENU = 'Approval of a Transfer Header document is requested';
        TransferHeaderApprovalRequestCancelEventDescTxt_gTxt: TextConst ENU = 'Approval of a Transfer Header document is Canceled';
}