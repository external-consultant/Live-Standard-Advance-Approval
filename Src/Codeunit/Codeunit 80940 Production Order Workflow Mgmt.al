
codeunit 80940 "Production Order Workflow Mgmt"
{
    Permissions = tabledata "Approval Entry" = rimd;

    [IntegrationEvent(false, false)]
    procedure OnSendProductionOrderForApproval(Var ProductionOrder: Record "Production Order")
    var
    Begin
    End;

    [IntegrationEvent(false, false)]
    procedure OnCancleProductionOrderForApproval(Var ProductionOrder: Record "Production Order")
    var
    Begin
    End;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProductionApprovalPossible(var ProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    procedure CheckProductionOrderApprovalWorkFlowEnable(Var ProductionOrder: Record "Production Order"): Boolean
    var
        IsHandled: Boolean;
    Begin
        OnBeforeCheckProductionApprovalPossible(ProductionOrder, IsHandled);
        if IsHandled then
            exit;

        If Not IsProductionOrderApprovalWorkFlowEnable(ProductionOrder) then
            Error(NoWorkFlowEnableErr_gTxt);
        exit(true);
    End;

    procedure IsProductionOrderApprovalWorkFlowEnable(Var ProductionOrder: Record "Production Order"): Boolean
    var
    Begin
        If ProductionOrder."Order Status" <> ProductionOrder."Order Status"::Open then
            exit(false);
        exit(WorkflowManagement_gCdu.CanExecuteWorkflow(ProductionOrder, RunWorkflowOnSendProductionOrderForApprovalCode()))
    End;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnPopulateApprovalEntryArgument', '', true, true)]
    local procedure OnPopulateApprovalEntryArgument(var RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry")
    Var
        ProductionOrder_lRec: Record "Production Order";
    begin
        Case RecRef.Number of
            Database::"Production Order":
                begin
                    //Insert the data to approval entries
                    RecRef.SetTable(ProductionOrder_lRec);
                    ApprovalEntryArgument."Document No." := ProductionOrder_lRec."No.";
                    ApprovalEntryArgument."Document Type" := ApprovalEntryArgument."Document Type"::Order;
                end;
        End;
    end;





    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsTolibrary', '', true, true)]
    local procedure OnAddWorkflowEventsToLibrary()
    var
        WorkflowEvent_lrec: Record "Workflow Event";
    begin
        // WorkflowEvent_lrec.Reset();
        // WorkflowEvent_lrec.SetFilter(Description, '%1', ProductionOrderSendForApprovalEventDescTxt_gTxt);
        // if WorkflowEvent_lrec.FindFirst() then
        //     WorkflowEvent_lrec.Delete(true);
        // WorkflowEvent_lrec.Reset();
        // WorkflowEvent_lrec.SetFilter(Description, '%1', ProductionOrderApprovalRequestCancelEventDescTxt_gTxt);
        // if WorkflowEvent_lrec.FindFirst() then
        //     WorkflowEvent_lrec.Delete(true);
        WorkflowEventHandling_gCdu.AddEventToLibrary(RunWorkflowOnSendProductionOrderForApprovalCode, Database::"Production Order", ProductionOrderSendForApprovalEventDescTxt_gTxt, 0, false);
        WorkflowEventHandling_gCdu.AddEventToLibrary(RunWorkflowOnCancelProductionOrderApprovalCode, Database::"Production Order", ProductionOrderApprovalRequestCancelEventDescTxt_gTxt, 0, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddworkflowEventPredecessorsToLibrary', '', true, true)]
    local procedure OnAddworkflowEventPredecessorsTolibrary(EventFunctionName: Code[128])
    var
        WorkFlow_lRec: Record "Workflow Event";
        DynaReqEntity_lRec: Record "Dynamic Request Page Entity";
    begin
        case EventFunctionName of
            RunWorkflowonCancelProductionOrderApprovalCode:
                WorkflowEventHandling_gCdu.AddEventPredecessor(RunWorkflowonCancelProductionOrderApprovalCode, RunWorkflowOnSendProductionOrderForApprovalCode);
            WorkflowEventHandling_gCdu.RunWorkflowOnApproveApprovalRequestCode:
                WorkflowEventHandling_gCdu.AddEventPredecessor(WorkflowEventHandling_gCdu.RunWorkflowOnApproveApprovalRequestCode, RunWorkflowOnSendProductionOrderForApprovalCode);
        end;
        WorkFlow_lRec.reset;
        WorkFlow_lRec.get(EventFunctionName);
        DynaReqEntity_lRec.reset;
        DynaReqEntity_lRec.SetRange("Table ID", WorkFlow_lRec."Table ID");
        if not DynaReqEntity_lRec.FindFirst() then begin
            DynaReqEntity_lRec.Init();
            DynaReqEntity_lRec.Description := 'Production Order';
            DynaReqEntity_lRec.Name := 'PRODUCTIONDOC';
            DynaReqEntity_lRec."Table ID" := WorkFlow_lRec."Table ID";
            DynaReqEntity_lRec."Related Table ID" := Database::"Prod. Order Line";
            DynaReqEntity_lRec."Sequence No." := 1;
            DynaReqEntity_lRec.insert;
            WorkFlow_lRec."Dynamic Req. Page Entity Name" := DynaReqEntity_lRec.Name;
            WorkFlow_lRec.Modify();
        end else begin
            WorkFlow_lRec."Dynamic Req. Page Entity Name" := DynaReqEntity_lRec.Name;
            WorkFlow_lRec.Modify();
        end;
    end;

    procedure RunWorkflowOnSendProductionOrderForApprovalCode(): code[128]
    begin
        exit(UpperCase('RUNWORKFLOWONSENDPRODUCTIONORDERFORAPPROVAL'))
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Production Order Workflow Mgmt", 'OnSendProductionOrderForApproval', '', true, true)]
    local procedure RunWorkflowOnSendProductionOrderForApproval(Var ProductionOrder: Record "Production Order")
    begin
        Workflowmanagement_gCdu.HandleEvent(RunWorkflowOnSendProductionOrderForApprovalCode, ProductionOrder);
    end;

    procedure RunWorkflowOnCancelProductionOrderApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelProductionOrderApproval'));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Production Order Workflow Mgmt", 'OnCancleProductionOrderForApproval', '', true, true)]
    local procedure RunWorkflowOnCancelProductionOrderApproval(Var ProductionOrder: Record "Production Order")
    begin
        Workflowmanagement_gCdu.HandleEvent(RunWorkflowOnCancelProductionOrderApprovalCode, ProductionOrder);
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnOpenDocument', '', true, true)]
    local procedure OnOpenDocument(RecRef: RecordRef; Var Handled: Boolean)
    var
        ProductionOrder_lRec: Record "Production Order";
    begin
        CASE RecRef.NUMBER OF
            DATABASE::"Production Order":
                begin
                    RecRef.SetTable(ProductionOrder_lRec);
                    ProductionOrder_lRec."Order Status" := ProductionOrder_lRec."Order Status"::Open;
                    ProductionOrder_lRec.Modify;
                    Handled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnReleaseDocument', '', true, true)]
    local procedure OnReleaseDocument(RecRef: RecordRef; Var Handled: Boolean)
    var
        ProductionOrder_lRec: Record "Production Order";
    begin
        CASE RecRef.NUMBER OF
            DATABASE::"Production Order":
                begin
                    RecRef.SetTable(ProductionOrder_lRec);
                    ProductionOrder_lRec."Order Status" := ProductionOrder_lRec."Order Status"::Released;
                    //Codeunit.Run(Codeunit::"Release Production Document", ProductionOrder_lRec);
                    If ProductionOrder_lRec."First Approval Completed" = false then
                        ProductionOrder_lRec."First Approval Completed" := true;
                    Clear(ProductionOrder_lRec."Workflow Category Type");
                    ProductionOrder_lRec.Modify;
                    Handled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSetStatusToPendingApproval', '', true, true)]
    local procedure OnSetStatusToPendingApproval(RecRef: RecordRef; Var Variant: Variant; Var IsHandled: Boolean)
    var
        ProductionOrder_lRec: Record "Production Order";
    begin
        CASE RecRef.NUMBER OF
            DATABASE::"Production Order":
                begin
                    RecRef.SetTable(ProductionOrder_lRec);
                    ProductionOrder_lRec."Order status" := ProductionOrder_lRec."Order Status"::"Pending Approval";
                    ProductionOrder_lRec.Modify;
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
                WorkflowResponseHandling_lCdu.AddResponsePredecessor(WorkflowResponseHandling_lCdu.SetStatusToPendingApprovalCode, RunWorkflowOnSendProductionOrderForApprovalCode);
            WorkflowResponseHandling_lCdu.SendApprovalRequestForApprovalCode:
                WorkflowResponseHandling_lCdu.AddResponsePredecessor(WorkflowResponseHandling_lCdu.SendApprovalRequestForApprovalCode, RunWorkflowOnSendProductionOrderForApprovalCode);
            WorkflowResponseHandling_lCdu.CancelAllApprovalRequestsCode:
                WorkflowResponseHandling_lCdu.AddResponsePredecessor(WorkflowResponseHandling_lCdu.CancelAllApprovalRequestsCode, RunWorkflowOnCancelProductionOrderApprovalCode);
            WorkflowResponseHandling_lCdu.OpenDocumentCode:
                WorkflowResponseHandling_lCdu.AddResponsePredecessor(WorkflowResponseHandling_lCdu.OpenDocumentCode, RunWorkflowOnCancelProductionOrderApprovalCode);
        End;
    end;


    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Production Order Workflow Mgmt", OnBeforeCheckProductionApprovalPossible, '', false, false)]
    // local procedure "Approvals Mgmt._OnBeforeCheckProductionApprovalPossible"(var ProductionOrder: Record "Production Order")
    // begin
    //     RunFieldMadatoryCheckProduction(ProductionOrder);
    // end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"ProductionOrder-Post Shipment", OnBeforeOnRun, '', false, false)]
    // local procedure "ProductionOrder-Post Shipment_OnBeforeOnRun"(var ProductionOrder: Record "Production Order"; var HideValidationDialog: Boolean; var SuppressCommit: Boolean; var IsHandled: Boolean)
    // begin
    //     RunFieldMadatoryCheckProduction(ProductionOrder);
    // end;



    /*
    procedure RunFieldMadatoryCheckProduction(var ProductionOrder: Record "Production Order")
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
        ProductionOrderDocNoFilter_lText: Text;
        RecordRef_lSH: RecordRef;
        TemplateFound_lCode: Code[10];
        TemplateFound_lInt: Integer;
    begin


        ProductionOrderDocNoFilter_lText := ',Field1=1(' + ProductionOrder."No." + '))';

        TemplateFound_lCode := '';
        FieldMandtempSetup_lRec.Reset();
        FieldMandtempSetup_lRec.SetRange("Record Type", FieldMandtempSetup_lRec."Record Type"::"Production Document");
        FieldMandtempSetup_lRec.SetRange(Enabled, true);
        FieldMandtempSetup_lRec.SetRange("Table Id", Database::"Production Order");
        If FieldMandtempSetup_lRec.FindSet() then
            repeat
                Clear(ConditionFilter_lText);
                ConditionFilter_lText := CopyStr(GetConditionAsDisplayText(FieldMandtempSetup_lRec), 1, StrLen(GetConditionAsDisplayText(FieldMandtempSetup_lRec)) - 1);
                ConditionFilter_lText := ConditionFilter_lText + ProductionOrderDocNoFilter_lText;
                if TemplateFound_lCode = '' then begin
                    RecordRef_lSH.Open(Database::"Production Order");
                    RecordRef_lSH.SetView(ConditionFilter_lText);
                    if RecordRef_lSH.FindFirst() then begin
                        TemplateFound_lCode := FieldMandtempSetup_lRec."Config. Template";
                        TemplateFound_lInt := FieldMandtempSetup_lRec.ID;
                    end;
                    RecordRef_lSH.Close();
                end;
            until FieldMandtempSetup_lRec.Next() = 0;



        ErrorMsgMgt.Activate(ErrorMsghandler);
        ConfTempHead_lRec.Reset();
        ConfTempHead_lRec.SetRange(Code, TemplateFound_lCode);
        ConfTempHead_lRec.SetRange("Table ID", Database::"Production Order");
        if ConfTempHead_lRec.FindFirst() then begin
            ConfTempLine_lRec.Reset();
            ConfTempLine_lRec.SetRange("Data Template Code", ConfTempHead_lRec.Code);
            if ConfTempLine_lRec.FindSet() then
                repeat
                    RecRef_lRrf.GetTable(ProductionOrder);
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
    //For Production Header Financial Fields

    [EventSubscriber(ObjectType::Table, Database::"Production Order", 'OnAfterValidateEvent', 'Transaction Type', true, true)]
    local procedure ProductionOrder_OnAfterValidateEvent_Transactiontype(var Rec: Record "Production Order"; var xRec: Record "Production Order"; CurrFieldNo: Integer)
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

    [EventSubscriber(ObjectType::Table, Database::"Production Order", 'OnAfterValidateEvent', 'Production-from Code', true, true)]
    local procedure ProductionOrder_OnAfterValidateEvent_TransactionfromCode(var Rec: Record "Production Order"; var xRec: Record "Production Order"; CurrFieldNo: Integer)
    var
        CategoryType: Code[10];
    begin
        If Rec.IsTemporary then
            exit;

        if not Rec."First Approval Completed" then
            exit;

        if CurrFieldNo <> Rec.FieldNo("Production-from Code") then
            exit;

        CategoryType := UpdateWorkflow('Financial', Rec."Workflow Category Type");

        if Rec."Workflow Category Type" <> CategoryType then begin
            Rec."Workflow Category Type" := CategoryType;
            Rec.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Order", 'OnAfterValidateEvent', 'Production-to Code', true, true)]
    local procedure ProductionOrder_OnAfterValidateEvent_Productiontocode(var Rec: Record "Production Order"; var xRec: Record "Production Order"; CurrFieldNo: Integer)
    var
        CategoryType: Code[10];
    begin
        If Rec.IsTemporary then
            exit;

        if not Rec."First Approval Completed" then
            exit;

        if CurrFieldNo <> Rec.FieldNo("Production-to Code") then
            exit;

        CategoryType := UpdateWorkflow('Financial', Rec."Workflow Category Type");

        if Rec."Workflow Category Type" <> CategoryType then begin
            Rec."Workflow Category Type" := CategoryType;
            Rec.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Order", 'OnAfterValidateEvent', 'In-Transit Code', true, true)]
    local procedure ProductionOrder_OnAfterValidateEvent_InTransitCode(var Rec: Record "Production Order"; var xRec: Record "Production Order"; CurrFieldNo: Integer)
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

    [EventSubscriber(ObjectType::Table, Database::"Production Order", 'OnAfterValidateEvent', 'Outbound Whse. Handling Time', true, true)]
    local procedure ProductionOrder_OnAfterValidateEvent_OutBoundWhseHandlingtime(var Rec: Record "Production Order"; var xRec: Record "Production Order"; CurrFieldNo: Integer)
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

    [EventSubscriber(ObjectType::Table, Database::"Production Order", 'OnAfterValidateEvent', 'Inbound Whse. Handling Time', true, true)]
    local procedure ProductionOrder_OnAfterValidateEvent_InBoundWhseHandling(var Rec: Record "Production Order"; var xRec: Record "Production Order"; CurrFieldNo: Integer)
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


    //For Production Header Non-Financial Fields
    [EventSubscriber(ObjectType::Table, Database::"Production Order", 'OnAfterValidateEvent', 'Vehicle No.', true, true)]
    local procedure ProductionOrder_OnAfterValidateEvent_VehicleNo(var Rec: Record "Production Order"; var xRec: Record "Production Order"; CurrFieldNo: Integer)
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

    [EventSubscriber(ObjectType::Table, Database::"Production Order", 'OnAfterValidateEvent', 'Shipment Method Code', true, true)]
    local procedure ProductionOrder_OnAfterValidateEvent_Shipmentmethodcode(var Rec: Record "Production Order"; var xRec: Record "Production Order"; CurrFieldNo: Integer)
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

    [EventSubscriber(ObjectType::Table, Database::"Production Order", 'OnAfterValidateEvent', 'Shipment Date', true, true)]
    local procedure ProductionOrder_OnAfterValidateEvent_ShipmentDate(var Rec: Record "Production Order"; var xRec: Record "Production Order"; CurrFieldNo: Integer)
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

    [EventSubscriber(ObjectType::Table, Database::"Production Order", 'OnAfterValidateEvent', 'Receipt Date', true, true)]
    local procedure ProductionOrder_OnAfterValidateEvent_ReceiptDate(var Rec: Record "Production Order"; var xRec: Record "Production Order"; CurrFieldNo: Integer)
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

    [EventSubscriber(ObjectType::Table, Database::"Production Order", 'OnAfterValidateEvent', 'Vehicle Type', true, true)]
    local procedure ProductionOrder_OnAfterValidateEvent_VehicleType(var Rec: Record "Production Order"; var xRec: Record "Production Order"; CurrFieldNo: Integer)
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
    */

    [EventSubscriber(ObjectType::Page, Page::"Prod. Order Components", OnBeforeReserveComp, '', false, false)]
    local procedure "Prod. Order Components_OnBeforeReserveComp"(var Sender: Page "Prod. Order Components"; var ProdOrderComp: Record "Prod. Order Component"; xProdOrderComp: Record "Prod. Order Component"; var ShouldReserve: Boolean)
    Var
        ProductionOrder_lRec: Record "Production Order";
    begin
        if ProdOrderComp.Status <> ProdOrderComp.Status::"Firm Planned" then
            exit;
        if ProductionOrder_lRec.Get(ProdOrderComp.Status, ProdOrderComp."Prod. Order No.") then begin
            if ProductionOrder_lRec."Order Status" in [ProductionOrder_lRec."Order Status"::Released, ProductionOrder_lRec."Order Status"::"Pending Approval", ProductionOrder_lRec."Order Status"::Closed] then
                Error('Order Status Should be Reopen.');
        end;

    end;

    procedure RejectedApprovalEntry(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.Validate(Status, ApprovalEntry.Status::Rejected);
        ApprovalEntry.Modify(true);
    end;

    var
        WorkflowManagement_gCdu: Codeunit "Workflow Management";
        NoWorkFlowEnableErr_gTxt: TextConst ENU = 'No approval workflow for this record type is enable.';

        WorkflowEventHandling_gCdu: Codeunit 1520;
        ProductionOrderSendForApprovalEventDescTxt_gTxt: TextConst ENU = 'Approval of a Production Order document is requested';
        ProductionOrderApprovalRequestCancelEventDescTxt_gTxt: TextConst ENU = 'Approval of a Production Order document is Canceled';
}