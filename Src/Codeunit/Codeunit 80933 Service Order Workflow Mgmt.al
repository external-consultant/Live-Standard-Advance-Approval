codeunit 80933 "Service Order Workflow Mgmt"
{
    [IntegrationEvent(false, false)]
    procedure OnSendServiceHeaderForApproval(Var ServiceHeader: Record "Service Header")
    var
    Begin
    End;

    [IntegrationEvent(false, false)]
    procedure OnCancleServiceHeaderForApproval(Var ServiceHeader: Record "Service Header")
    var
    Begin
    End;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServiceApprovalPossible(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    procedure CheckServiceHeaderApprovalWorkFlowEnable(Var ServiceHeader: Record "Service Header"): Boolean
    var
        IsHandled: Boolean;
    Begin
        OnBeforeCheckServiceApprovalPossible(ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        If Not IsServiceHeaderApprovalWorkFlowEnable(ServiceHeader) then
            Error(NoWorkFlowEnableErr_gTxt);
        exit(true);
    End;

    procedure IsServiceHeaderApprovalWorkFlowEnable(Var ServiceHeader: Record "Service Header"): Boolean
    var
    Begin
        If ServiceHeader."Approval Status 2" <> ServiceHeader."Approval Status 2"::Open then
            exit(false);
        exit(WorkflowManagement_gCdu.CanExecuteWorkflow(ServiceHeader, RunWorkflowOnSendServiceHeaderForApprovalCode()))
    End;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnPopulateApprovalEntryArgument', '', true, true)]
    local procedure OnPopulateApprovalEntryArgument(var RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry")
    Var
        ServiceHeader_lRec: Record "Service Header";
    begin
        Case RecRef.Number of
            Database::"Service Header":
                begin
                    //Insert the data to approval entries
                    RecRef.SetTable(ServiceHeader_lRec);
                    ApprovalEntryArgument."Document No." := ServiceHeader_lRec."No.";
                    ApprovalEntryArgument."Document Type" := ServiceHeader_lRec."Document Type";
                end;
        End;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsTolibrary', '', true, true)]
    local procedure OnAddWorkflowEventsToLibrary()
    begin
        WorkflowEventHandling_gCdu.AddEventToLibrary(RunWorkflowOnSendServiceHeaderForApprovalCode, Database::"Service Header", ServiceHeaderSendForApprovalEventDescTxt_gTxt, 0, false);
        WorkflowEventHandling_gCdu.AddEventToLibrary(RunWorkflowOnCancelServiceHeaderApprovalCode, Database::"Service Header", ServiceHeaderApprovalRequestCancelEventDescTxt_gTxt, 0, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddworkflowEventPredecessorsToLibrary', '', true, true)]
    local procedure OnAddworkflowEventPredecessorsTolibrary(EventFunctionName: Code[128])
    begin
        case EventFunctionName of
            RunWorkflowonCancelServiceHeaderApprovalCode:
                WorkflowEventHandling_gCdu.AddEventPredecessor(RunWorkflowonCancelServiceHeaderApprovalCode, RunWorkflowOnSendServiceHeaderForApprovalCode);
            WorkflowEventHandling_gCdu.RunWorkflowOnApproveApprovalRequestCode:
                WorkflowEventHandling_gCdu.AddEventPredecessor(WorkflowEventHandling_gCdu.RunWorkflowOnApproveApprovalRequestCode, RunWorkflowOnSendServiceHeaderForApprovalCode);

        end;
    end;

    procedure RunWorkflowOnSendServiceHeaderForApprovalCode(): code[128]
    begin
        exit(UpperCase('RUNWORKFLOWONSENDSERVICEHEADERFORAPPROVAL'))
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Order Workflow Mgmt", 'OnSendServiceHeaderForApproval', '', true, true)]
    local procedure RunWorkflowOnSendServiceHeaderForApproval(Var ServiceHeader: Record "Service Header")
    begin
        Workflowmanagement_gCdu.HandleEvent(RunWorkflowOnSendServiceHeaderForApprovalCode, ServiceHeader);
    end;

    procedure RunWorkflowOnCancelServiceHeaderApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunkorkflowOnCancelServiceHeaderApproval'));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Order Workflow Mgmt", 'OnCancleServiceHeaderForApproval', '', true, true)]
    local procedure RunWorkflowOnCancelServiceHeaderApproval(Var ServiceHeader: Record "Service Header")
    begin

        Workflowmanagement_gCdu.HandleEvent(RunWorkflowOnCancelServiceHeaderApprovalCode, ServiceHeader);
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnOpenDocument', '', true, true)]
    local procedure OnOpenDocument(RecRef: RecordRef; Var Handled: Boolean)
    var
        ServiceHeader_lRec: Record "Service Header";
    begin
        CASE RecRef.NUMBER OF
            DATABASE::"Service Header":
                begin
                    RecRef.SetTable(ServiceHeader_lRec);
                    ServiceHeader_lRec."Approval Status 2" := ServiceHeader_lRec."Approval Status 2"::Open;
                    ServiceHeader_lRec.Modify;
                    Handled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnReleaseDocument', '', true, true)]
    local procedure OnReleaseDocument(RecRef: RecordRef; Var Handled: Boolean)
    var
        ServiceHeader_lRec: Record "Service Header";
    begin
        CASE RecRef.NUMBER OF
            DATABASE::"Service Header":
                begin
                    RecRef.SetTable(ServiceHeader_lRec);
                    ServiceHeader_lRec."Approval Status 2" := ServiceHeader_lRec."Approval Status 2"::Released;                    
                    if ServiceHeader_lRec."First Approval Completed" = false then
                        ServiceHeader_lRec."First Approval Completed" := true;
                    Clear(ServiceHeader_lRec."Workflow Category Type");
                    ServiceHeader_lRec.Modify;
                    Handled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSetStatusToPendingApproval', '', true, true)]
    local procedure OnSetStatusToPendingApproval(RecRef: RecordRef; Var Variant: Variant; Var IsHandled: Boolean)
    var
        ServiceHeader_lRec: Record "Service Header";
    begin
        CASE RecRef.NUMBER OF
            DATABASE::"Service Header":
                begin
                    RecRef.SetTable(ServiceHeader_lRec);
                    ServiceHeader_lRec."Approval Status 2" := ServiceHeader_lRec."Approval Status 2"::"Pending Approval";
                    ServiceHeader_lRec.Modify;
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
                WorkflowResponseHandling_lCdu.AddResponsePredecessor(WorkflowResponseHandling_lCdu.SetStatusToPendingApprovalCode, RunWorkflowOnSendServiceHeaderForApprovalCode);
            WorkflowResponseHandling_lCdu.SendApprovalRequestForApprovalCode:
                WorkflowResponseHandling_lCdu.AddResponsePredecessor(WorkflowResponseHandling_lCdu.SendApprovalRequestForApprovalCode, RunWorkflowOnSendServiceHeaderForApprovalCode);
            WorkflowResponseHandling_lCdu.CancelAllApprovalRequestsCode:
                WorkflowResponseHandling_lCdu.AddResponsePredecessor(WorkflowResponseHandling_lCdu.CancelAllApprovalRequestsCode, RunWorkflowOnCancelServiceHeaderApprovalCode);
            WorkflowResponseHandling_lCdu.OpenDocumentCode:
                WorkflowResponseHandling_lCdu.AddResponsePredecessor(WorkflowResponseHandling_lCdu.OpenDocumentCode, RunWorkflowOnCancelServiceHeaderApprovalCode);
        End;
    end;



    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Order Workflow Mgmt", OnBeforeCheckServiceApprovalPossible, '', false, false)]
    local procedure "Approvals Mgmt._OnBeforeCheckTransferApprovalPossible"(var ServiceHeader: Record "Service Header")
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
        ServiceHeaderDocNoFilter_lText: Text;
        RecordRef_lSH: RecordRef;
        TemplateFound_lCode: Code[10];
        TemplateFound_lInt: Integer;
    begin
        // FieldMandatorySetup_lRec.Get();
        // FieldMandatorySetup_lRec.TestField("Serv. Head. Config. Template");

        ServiceHeaderDocNoFilter_lText := ',Field3=1(' + ServiceHeader."No." + '))';

        TemplateFound_lCode := '';
        FieldMandtempSetup_lRec.Reset();
        FieldMandtempSetup_lRec.SetRange("Record Type", FieldMandtempSetup_lRec."Record Type"::"Service Document");
        FieldMandtempSetup_lRec.SetRange(Enabled, true);
        FieldMandtempSetup_lRec.SetRange("Table Id", Database::"Service Header");
        If FieldMandtempSetup_lRec.FindSet() then
            repeat
                Clear(ConditionFilter_lText);
                ConditionFilter_lText := CopyStr(GetConditionAsDisplayText(FieldMandtempSetup_lRec), 1, StrLen(GetConditionAsDisplayText(FieldMandtempSetup_lRec)) - 1);
                ConditionFilter_lText := ConditionFilter_lText + ServiceHeaderDocNoFilter_lText;
                if TemplateFound_lCode = '' then begin
                    RecordRef_lSH.Open(Database::"Service Header");
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
        ConfTempHead_lRec.SetRange("Table ID", Database::"Service Header");
        if ConfTempHead_lRec.FindFirst() then begin
            ConfTempLine_lRec.Reset();
            ConfTempLine_lRec.SetRange("Data Template Code", ConfTempHead_lRec.Code);
            if ConfTempLine_lRec.FindSet() then
                repeat
                    RecRef_lRrf.GetTable(ServiceHeader);
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

    var
        WorkflowManagement_gCdu: Codeunit "Workflow Management";
        NoWorkFlowEnableErr_gTxt: TextConst ENU = 'No approval workflow for this record type is enable.';

        WorkflowEventHandling_gCdu: Codeunit 1520;
        ServiceHeaderSendForApprovalEventDescTxt_gTxt: TextConst ENU = 'Approval of a ServiceHeader document is requested';
        ServiceHeaderApprovalRequestCancelEventDescTxt_gTxt: TextConst ENU = 'Approval of a ServiceHeader document is Canceled';
}